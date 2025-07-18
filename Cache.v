

module CACHE_CONTROLLER(address,clk_cc,data,mode,output_data,hit1, hit2,Wait, stored_address, stored_data);


input [no_of_address_bits-1:0] address;  
input clk_cc;
input [byte_size-1:0] data; 
input mode;            //mode=0 : Read  ,  mode=1 : Write

output reg[byte_size-1:0] output_data;
output reg hit1, hit2;         //hit1=1 shows that the requested memory was found in L1 Cache ,similary hit2 for L2 Cache
output reg Wait;            //Wait=1 is a signal for the processor...that the cache controller is currently working on some read/write operation and processor needs to wait before the controller accepts next read/write operation

output reg [no_of_address_bits-1:0] stored_address ;       //the address stored in cache controller while it is processing 
output reg [byte_size-1:0]stored_data ;   //the stored data in cache controller...in case the user changes inbetween the process

reg stored_mode ;        //the stored mode (read or write)
reg Ccount = 0 ;   //for initializing the stored values in starting


// general parameters

parameter no_of_address_bits = 32;    
parameter no_of_blkoffset_bits = 2;
parameter byte_size = 8;         //one block is of 8 bits


        ///     *** L1 Cache ***    \\\\\\

// L1 Cache Paramters

parameter l1_blocks = 32;       // No. of lines in L1 Cache... as one line contains 1 block...it is equal to no. of blocks
parameter l1_block_bit_size = 32;     //Size of each line = No. of blocks in a line * No. of bytes in a block * Byte_size = 1*4*8=32
parameter no_of_l1_index_bits = 5;    //as 2^5=32... So 5 index bits are sufficient to locate a line on L1 Cache
parameter no_of_l1_tag_bits = 25;     //No. of tag bits= Address_bits - index_bits- Block_offset = 32 -5 -2 =25

// L1 CACHE Memory allocations

reg [no_of_l1_tag_bits-1:0] l1_tag ;         //The tag for lines on L1 Cache
reg [no_of_l1_index_bits-1:0] l1_index ;         //Represents the index of the line to which the address belongs on L1 Cache

reg [l1_block_bit_size-1:0] l1_cache_memory[0:l1_blocks-1];    //An array of blocks for L1 Cache memory where each element contains No. of l1_block_bit_size bits
reg [no_of_l1_tag_bits-1:0] l1_tag_array[0:l1_blocks-1];  //Tag array for L1 Cache memory where each element contains no_of_tag_bits bits
reg l1_valid[0:l1_blocks-1];      //The valid array for L1 Cache containing 1 if it is valid or 0 if invalid
                                        //valid means if there is some block stored at some location in L1 Cache...initially as Cache is empty...all postions are invalid

// L1 CACHE vaild and tag array initialization

initial 
begin: initialization_l1           
    integer i;
    for  (i=0;i<l1_blocks;i=i+1)
    begin
        l1_valid[i]=1'b0;   //initially as the cache is empty...all the locations on the Cache are invalid
        l1_tag_array[i]=0;  //set tag to 0...we can set tag to some other random value as well
    end
end

     // *** L2 CACHE *** \\\\\

// L2 CACHE Parameters

parameter no_of_l2_ways = 4;        //No. of ways in a set... here 4 as it is 4-way set-associative
parameter no_of_l2_ways_bits = 2;     //No. of bits to represent ways, 2 bits are sufficient to represent 4 values
parameter no_of_l2_blocks = 128;      //No. of lines in L2 Cache... each line is a set of 4 blocks here
parameter l2_block_bit_size = 128;     // No. of bits in a L2 Cache line = No.of bytes in a line * byte_size=16*8=128
parameter no_of_l2_index_bits = 7;     // 2^7=128 <= No. of L2 block lines.....So 7 bits are used here to get the no. of line on L2 Cache
parameter no_of_l2_tag_bits = 23;      //No. of tag bits= Address_bits - index_bits- Block_offset = 32 -9 -2 =23

// L2 Cache memory allocations

reg [no_of_l2_tag_bits-1:0] l2_tag ;              //The tag for lines on L2 Cache
reg [no_of_l2_index_bits-1:0] l2_index ;          //The index of the line to which the address belongs on L2 Cache
reg [no_of_blkoffset_bits-1:0]  offset ;           //Offset gives the index of byte within a block

reg [l2_block_bit_size-1:0] l2_cache_memory[0:no_of_l2_blocks-1];        //An array where each element if of l2_block_bit_size bits..for memory in L2 Cache
reg [(no_of_l2_tag_bits*no_of_l2_ways)-1:0] l2_tag_array[0:no_of_l2_blocks-1];  //The tag array where each element contains no_of_l2_tag_bits*NO_of_l2_ways bits
reg [no_of_l2_ways-1:0] l2_valid[0:no_of_l2_blocks-1];      //Is valid array where each element is of no_of_l2_ways bits


// L2 Cache LRU memory allocations

reg [no_of_l2_ways*no_of_l2_ways_bits-1:0] lru[0:no_of_l2_blocks-1];     //LRU array where each element is of no_of_l2_ways*no_of_l2_ways_bits bits

reg [no_of_l2_ways_bits-1:0] lru_value ;
reg [no_of_l2_ways_bits-1:0] lru_value_dummy ;

reg [no_of_l2_ways_bits-1:0] lru_value2 ;
reg [no_of_l2_ways_bits-1:0] lru_value_dummy2 ;

//for the delay counters to implement delays in the L2 Cache

reg [1:0]l2_delay_counter=0;
reg [3:0]main_memory_delay_count=0;
reg dummy_hit;
reg is_L2_delay=0;

// L2 cache valid and tag array initialization

initial 
begin: initialization
    integer i;
    for  (i=0;i<no_of_l2_blocks;i=i+1)
    begin
        l2_valid[i]=0;          //initially the cache is empty
        l2_tag_array[i]=0;         //set tag to some random
        lru[i]=8'b11100100;         //set the lru values to some random permutation of 0, 1, 2, 3 initially
    end
end


        /// *** MAIN MEMORY *** \\\\\

// main memory paramters 

parameter no_of_main_memory_blocks = 1024; // 2^10 blocks (each block = 1 line)
parameter main_memory_block_size = 32;     // 4 bytes per block × 8 bits = 32 bits
parameter no_of_bytes_main_memory_block = 4; // Each block has 4 bytes
parameter main_memory_byte_size = 4096;   // 1024 blocks × 4 bytes per block = 4096 bytes (4 KB)

// main memory -- memory allocations

reg [main_memory_block_size-1:0]main_memory[0:no_of_main_memory_blocks-1]; 

reg [no_of_address_bits-1:0] address_valid ;             //For Checking whether there is a stored block at some line in Cache or not
reg [no_of_address_bits-no_of_blkoffset_bits-1:0] main_memory_blk_id ;    //Represents the line number to which the address belongs on main memory

// for the delay counters to implement delays in the main memory

reg [1:0]l2_delay_counter_w = 0 ;
reg [3:0]main_memory_delay_counter_w = 0 ;
reg dummy_hit_w = 0 ;
reg is_L2_delay_w = 0 ;

// main memory data initialization

initial 
begin: initialization_main_memory
    integer i;
    for (i=0;i<no_of_main_memory_blocks;i=i+1)
    begin
        main_memory[i]=i;       //we can randomly intialize with some other value as well here
    end
end


// Latency paramters

parameter l1_latency = 1;         //It represents the delay in fetching a data from L1 Cache...1 here represents that it would be availabe within that clock cycle only
parameter l2_latency = 3;         //It represents the delay in fetching/searching_time in L2 Cache....It will lead to fetching data after passing of 2 clock cycles
parameter main_memory_latency = 10;      //It represents the delay in fetching/searching_times in main_memory.. It would lead to fetching data from main memory after passing of 9 clock cycles

integer i,j ;              //integer variables for working in for-loops

//the variable given below in various search operation in L1 , L2 and main memory
//specially when we need to evict some block from L1 or L2 Cache
//then it needs to be searched in the L2 or in main memory to update its value there

integer l1_l2_check ;
integer l1_l2_check2 ;
integer l1_l2_checka ;
integer l1_l2_check2a ;
integer l1_l2_checkb ;
integer l1_l2_check2b ;

integer l2_check ; 
integer l2_check2 ;
integer l2_checka ;
integer l2_check2a ;
integer l2_mm_check ;
integer l2_mm_check2 ;
integer l2_mm_iterator ;
integer l2_iterator ;


//Many times we need to evict an block from L1 or L2 Cache..
//so its value needs to be updated in L2 or main Memory
//these are the variable used for evicting operations
//for finding the block present in L1 or L2..its location in L2 or main memory

reg [no_of_l1_tag_bits-1:0] l1_evict_tag ;
reg [no_of_l2_tag_bits-1:0] l1_to_l2_tag ;
reg [no_of_l2_index_bits-1:0] l1_to_l2_index ;

reg [no_of_l1_tag_bits-1:0] l1_evict_tag2 ;
reg [no_of_l2_tag_bits-1:0] l1_to_l2_tag2 ;
reg [no_of_l2_index_bits-1:0] l1_to_l2_index2 ; 

reg [no_of_l1_tag_bits-1:0] l1_evict_tag3 ;
reg [no_of_l2_tag_bits-1:0] l1_to_l2_tag3 ;
reg [no_of_l2_index_bits-1:0] l1_to_l2_index3 ;

reg [no_of_l2_tag_bits-1:0] l2_evict_tag ;

//to store whether the block to be evicted was found in L2 or main memory or not

reg l1_to_l2_search;
reg l1_to_l2_search2;
reg l1_to_l2_search3;






       /// TODO : CACHE CONTROLLER LOGIC STARTS FROM HERE *** \\\\\

always @(posedge clk_cc)
begin
    if (Ccount==0)
        output_data = 0 ;
    if(Ccount==0 || Wait==0) //if the controller is not in wait state or it is the first operation after reset
                             //store the input from processor in cache controller
        begin
            stored_address = address ;
            Ccount = 1 ;
            stored_mode = mode ;
            stored_data = data ;
        end

        // ***? FIRST TASK IS TO ASSIGN THE BIT RANGES FOR INDEX,TAG OF L1,L2 FROM ADDRESS 
  
    main_memory_blk_id = (stored_address>>no_of_blkoffset_bits) % no_of_main_memory_blocks ; //the index of address in main memory

    l1_index = (main_memory_blk_id) % l1_blocks ;  //The index in L1 Cache for the address
    l1_tag = main_memory_blk_id >> no_of_l1_index_bits ;//The tag for the address in L1 Cache

    l2_index = (main_memory_blk_id) % no_of_l2_blocks ;  //the index of the address in L2 Cache
    l2_tag = main_memory_blk_id >> no_of_l2_index_bits ;     //The tag for the address in L2 Cache
    
    offset = stored_address % no_of_bytes_main_memory_block ;  //the offset...to extract the particular byte from a block
    if (stored_mode==0)
    begin
       

        // *****? SECOND TASK IS TO CHECK WHETHER DATA IS PRESENT IN L1 CACHE OR NOT ?
       
        if (l1_valid[l1_index]&&l1_tag_array[l1_index]==l1_tag) //if the tag matches and the valid is true for the location in L1 Cache..then the address is found in L1 Cache
        begin
          
            output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size]; //extract the exact byte from the L1 Cache
            hit1=1;     //found in L1 Cache
            hit2=0;        //not found in L2 Cache
            Wait=0;         //as found in L1, the controller is ready for next instruction
        end
       
        else
        begin
           
            // *****? THIRD TASK IS TO CHECK IN L2 CACHE IF DATA IS NOT PRESENT IN L1 CACHE ALONG WITH ADDING LATERNCY TO L2 CACHE

           
            hit1=0;     //not found in L1 Cache
            if (l2_delay_counter < l2_latency && is_L2_delay == 0)      //a counter to implement the delay for searching in L2 Cache
            begin
                hit2=0;     //not found in L2 Cache till now
                hit1=0;     //not found in L1 Cache
                l2_delay_counter = l2_delay_counter + 1 ;          //increment the counter variable in every cycle
                Wait=1;     //the controller is still searching the address.. so can't accept new request from processor at present
            end
            else
            begin //Actual searching in L2 Cache begins
                l2_delay_counter=0;     //resetting the counter for delay in next input
                //hit1=0;     //not found in L1 Cache
                hit2=1;     //Let's assume it would be found in L2 Cache
                Wait=0;     //Assuming it would be found in L2 Cache, so wait would be zero
                dummy_hit=0;
                for (l2_check=0;l2_check<no_of_l2_ways;l2_check=l2_check+1)     //now checking for every block in the set in L2 Cache required index line
                begin
                    if (l2_valid[l2_index][l2_check]&&l2_tag_array[l2_index][((l2_check+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l2_tag) //if the tag matches and is valid
                    begin
                        dummy_hit=1;        //We have successfully found the address (in L2 Cache)
                        l2_check2=l2_check;      //We store the block in which the address was found
                    end
                end
                if (dummy_hit==1)       //if the address was found in L2 Cache
                begin

                    // *****? FOURTH TASK IS TO UPDATE THE LRU ARRAY FOR THE EVICTION OF BLOCK IN FUTURE 

                    lru_value2=lru[l2_index][((l2_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]; //lRU value for the block where the address was found
                    for (l2_iterator=0;l2_iterator<no_of_l2_ways;l2_iterator=l2_iterator+1)     //Updating the LRU values of all the blocks by iterating over all the 4 blocks in the L2 Line
                    begin
                       lru_value_dummy2=lru[l2_index][((l2_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]; //get current LRU value of the current block in the loop (iteration)
                       if (lru_value_dummy2>lru_value2)     //We only need to update the LRU values of the blocks with LRU values strictly greater than the new LRU value of found block... That is we update the LRU values of all 3 blocks except the found block whose LRU we update at last
                       begin
                           lru[l2_index][((l2_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=lru_value_dummy2-1; //we reduce the LRU value of the block here by 1
                       end
                    end
                    lru[l2_index][((l2_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=no_of_l2_ways-1; //the found block was most recent ...so its LRU must be higest here... that is no. of ways -1 =3
                    
                   

                   
                    //  *****? FIVETH TASK IS transferring the L2 Block to L1 Cache 

                    if (l1_valid[l1_index]==0)      //if the particular mapped block in L1 Cache in empty/not valid
                    begin
                        l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];     //copy the data to L1
                        l1_valid[l1_index]=1;       //set valid for the respective block to 1
                        l1_tag_array[l1_index]=l1_tag;  //update the tag for the block
                        output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size]; //taking the data as the output data
                    end

                    else
                    begin      

                      // *****? SIXTH TASK IS - if there is already a valid block present at the particular line
                        l1_evict_tag2=l1_tag_array[l1_index];   //the tag of the block in L2 to be evicted
                        l1_to_l2_tag2=l1_evict_tag2>>(no_of_l1_tag_bits-no_of_l2_tag_bits);     //retriving the tag of the block in L2 who has to be evicted in L1
                        l1_to_l2_index2={l1_evict_tag2[no_of_l1_tag_bits-no_of_l2_tag_bits-1:0],l1_index}; //retriving the index of the block in L2 who has to be evicted in L1
                        l1_to_l2_search2=0;             //now after knowing the line, we need to get the block in which it is present among the 4 ways in the L2 cache
                        for (l1_l2_checka=0;l1_l2_checka<no_of_l2_ways;l1_l2_checka=l1_l2_checka+1)
                        begin
                            if (l2_valid[l1_to_l2_index2][l1_l2_checka]&&l2_tag_array[l1_to_l2_index2][((l1_l2_checka+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l1_to_l2_tag2)  //checking in the loop whether the current block is the block that is searched
                            begin
                                l1_to_l2_search2=1;         //indicating that it was found in L2
                                l1_l2_check2a=l1_l2_checka;    //storing the index of the block in set in which it is present
                            end
                        end
                        if (l1_to_l2_search2==1)   //now after getting the whole location in L2 cache for the block that is to be evicted, we now evict the block from L1 , update the data in L2 and place the new block in L1 replacing it
                        begin
                            
                            l2_cache_memory[l1_to_l2_index2][((l1_l2_check2a+1)*l1_block_bit_size-1)-:l1_block_bit_size]=l1_cache_memory[l1_index];
                            l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                            l1_valid[l1_index]=1;
                            l1_tag_array[l1_index]=l1_tag;
                            output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                            //dummy_hit=1;
                        end
                        else
                        begin //if not found in L2, then definitely, it would be in main Memory, so we update the data in main memory and then place the found block in L1 Cache
                            main_memory[{l1_evict_tag2,l1_index}]=l1_cache_memory[l1_index];
                            l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                            l1_valid[l1_index]=1;
                            l1_tag_array[l1_index]=l1_tag;
                            output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                            //dummy_hit=1;
                        end
                    end
                end
               
                else
                //  ******?  SEVENTH TASK : if the address was not found in L1 cache and L2 Cache as well, we now search in Main Memory
                begin 
                    hit1=0;         //was Not found in L1
                    hit2=0;     //was not found in L2
                    Wait=1;         //still searching , so wait

                    if (main_memory_delay_count<main_memory_latency) //a counter loop to show the delays in searching in main memory
                    begin
                        main_memory_delay_count = main_memory_delay_count+1; //increase the counter variable each cycle
                        is_L2_delay=1;
                    end
                    else
                    begin // *** actual search in Main memory begins here  ***
                    
                        main_memory_delay_count=0;  //resetting the counter for delay in the next inputs 
                        is_L2_delay=0;
                        Wait=0;     //the block would definately be found here
                        l2_delay_counter=0;
                        //now we start the process of promoting the address to L2 Cache
                        for (l2_mm_check=0;l2_mm_check<no_of_l2_ways;l2_mm_check=l2_mm_check+1)   //searching for the least recently used block in L2 , so this block in main memory can replace that block in L2
                        begin
                            if (lru[l2_index][((l2_mm_check+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]==0)
                            begin
                                l2_mm_check2=l2_mm_check;
                            end
                        end
                        lru_value=lru[l2_index][((l2_mm_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];    //getting the lru values of the particular line in L2 Cache
                        //here we made a copy of the lru values and start updating these to replace the original lru values when complete
                        for (l2_mm_iterator=0;l2_mm_iterator<no_of_l2_ways;l2_mm_iterator=l2_mm_iterator+1)
                        begin
                            
                            lru_value_dummy=lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                            
                           if ((lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits])>lru_value)   
                           begin
                               lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=lru_value_dummy-1;         //here we update the lru values
                               lru_value_dummy=lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                              
                           end
                        end
                        lru[l2_index][((l2_mm_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=(no_of_l2_ways-1);       //now we place the block and make its lru value the highest .. indicating that its the most recent used
                        
                        // ? EIGTH TASK : copy the data into l1 and l2
                        
                        //** if the block to be replaced in L2 was empty/not valid
                        if (l2_valid[l2_index][l2_mm_check2]==0)       
                        begin
                            //here we just copy the data to L2 without any need to evict any block in L2 cache
                            
                            l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]=main_memory[main_memory_blk_id];
                            
                            l2_valid[l2_index][l2_mm_check2]=1;
                            
                            l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]=l2_tag;
                            
                        
                            //now we have started to procedure to place it in L1 Cache as well
                            if (l1_valid[l1_index]==0)
                            begin
                                
                               l1_cache_memory[l1_index]=main_memory[main_memory_blk_id];
                                
                                l1_valid[l1_index]=1;
                                
                                l1_tag_array[l1_index]=l1_tag;
                                
                                output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                dummy_hit=0; 
                            end
                            
                            else
                            begin
                                //** if there is a block in L1 Cache already at the particular line, then it needs to be evicted
                                //and the new block needs to be placed there
                                //just like the same procedure we have followed if it was found in L2 Cache instead of main memory
                                
                                l1_evict_tag=l1_tag_array[l1_index];
                               
                                l1_to_l2_tag=l1_evict_tag>>(no_of_l1_tag_bits-no_of_l2_tag_bits);
                                
                                l1_to_l2_index={l1_evict_tag[no_of_l1_tag_bits-no_of_l2_tag_bits-1:0],l1_index};
                                
                                l1_to_l2_search=0;
                                for (l1_l2_check=0;l1_l2_check<no_of_l2_ways;l1_l2_check=l1_l2_check+1)
                                begin
                                    if (l2_valid[l1_to_l2_index][l1_l2_check]&&l2_tag_array[l1_to_l2_index][((l1_l2_check+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l1_to_l2_tag)
                                    begin
                                        l1_to_l2_search=1;
                                        l1_l2_check2=l1_l2_check;
                                    end
                                end
                                //this is the same procedure as mentioned when the memory in L1 was to be replaced when the block was found in L2 Cache
                                //when the block to evicted was found in L2 Cache....so we need to update its value in L2 Cache location
                                if (l1_to_l2_search==1)
                                begin
                                    
                                    l2_cache_memory[l1_to_l2_index][((l1_l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]=l1_cache_memory[l1_index];
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                                else
                                //when the block to be evicted is not present in L2 Cache
                                //now the data stored in the main memory needs to be updated
                                begin
                                    main_memory[{l1_evict_tag,l1_index}]=l1_cache_memory[l1_index];
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
            
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                            end
                        end
                        
                        else
                        begin
                                    //*** if instead of invalid/empty location in L2, there was some block placed in L2 Cache
                            //here we evict the block in L2 and update its data in main memory

                            l2_evict_tag=l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits];
                            main_memory[{l2_evict_tag,l2_index}]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                            
                            l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]=main_memory[main_memory_blk_id];
                            l2_valid[l2_index][l2_mm_check2]=1;
                            l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]=l2_tag;
                            
                            
                            //now we are promoting the address to L1 Cache
                            //its the same method as discussed before for promotinng an address in L2 to L1 

                            if (l1_valid[l1_index]==0) //if the line at the L1 Cache was empty
                            begin
                                l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                l1_valid[l1_index]=1;
                                l1_tag_array[l1_index]=l1_tag;
                                output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                dummy_hit=0;
                            end
                            else
                            begin
                                //else there was some block placed in L1 Cache which needs to be evicted
                                //its the same method as mentioned before when the block in L1 is to be evicted to replace it with the found block
                                l1_evict_tag3=l1_tag_array[l1_index];
                                //here we are searching for the address of the block in L2 which has to be evicted from L1 Cache
                                //so that it can be update the data of the block to be evicted in L2 Cache
                                l1_to_l2_tag3=l1_evict_tag3>>(no_of_l1_tag_bits-no_of_l2_tag_bits);
                                l1_to_l2_index3={l1_evict_tag3[no_of_l1_tag_bits-no_of_l2_tag_bits-1:0],l1_index};
                                l1_to_l2_search3=0;
                                for (l1_l2_checkb=0;l1_l2_checkb<no_of_l2_ways;l1_l2_checkb=l1_l2_checkb+1)  
                                begin
                                    if (l2_valid[l1_to_l2_index3][l1_l2_checkb]&&l2_tag_array[l1_to_l2_index3][((l1_l2_checkb+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l1_to_l2_tag3)
                                    begin
                                        l1_to_l2_search3=1;
                                        l1_l2_check2b=l1_l2_checkb;
                                    end
                                end
                                //when we have found the block's location in  L2 Cache.. we update the data at block in L2 Cache
                                if (l1_to_l2_search3==1)
                                begin
                                    
                                    l2_cache_memory[l1_to_l2_index3][((l1_l2_check2b+1)*l1_block_bit_size-1)-:l1_block_bit_size]=l1_cache_memory[l1_index];
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                                else
                                begin
                                    //in case when the data at main memory needs to be updated...
                                    //it is when the block was not found in L2 Cache and now we must update its value in Main Memory
                                    main_memory[{l1_evict_tag3,l1_index}]=l1_cache_memory[l1_index];
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                            end
                        end
                    end    
                end //a.
            end //c.      
        end
    end

    else
    begin
        //? ***** In case when the processor gives **WRITE** operation   *****
        output_data=0;
        if (l1_valid[l1_index]&& l1_tag_array[l1_index]==l1_tag)        //checking conditions for it to be present in L1 Cache
        begin
           
            l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size]=stored_data;     //if found change the data at the location
            Wait=0;     //as it is found and the data is also changed, the controller is now ready to get new instructions from processor
            hit1=1;     //indicates that it was found on L1 Cache
            hit2=0;     //indicated that it was not found in L2 Cache
        end

        else
        begin  //else if, when not found in L1 Cache, we start searching on L2 Cache
            if((l2_delay_counter_w < l2_latency) && is_L2_delay_w==0)       //this is a small counter implementation to execute a delay for showing searching time in L2 Cache
            begin 
                l2_delay_counter_w=l2_delay_counter_w+1;        //increment the variable by 1 and check condition in every cycle
                hit1=0; //till now its not found in L1 Cache
                hit2=0; //till now its not found in L2 Cache
                Wait=1; //indicates that the controller is busy at present and processor needs to wait till the controller completes the write operation
            end

            else
            begin //Now, here is the code for checking if it is present in L2 Cache
                l2_delay_counter_w=0;   //Reset the delay counter for L2 Cache to zero for next inputs
                dummy_hit_w=0;     //We have still not found our required address
                hit1=0;         //Not found in L1 Cache
                hit2=0;         //Till now not found in L2 Cache
                for (l2_checka=0;l2_checka<no_of_l2_ways;l2_checka=l2_checka+1)         //Linear searching on all 4 ways in the L2 Cache line
                begin
                    if (l2_valid[l2_index][l2_checka]&&l2_tag_array[l2_index][((l2_checka+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l2_tag) //Comparing whether the address is required address or is the block valid
                    begin
                        dummy_hit_w=1;  //if we found the data in L2, hit=1... that is the data is found
                        hit2=1;     //Found in L2 Cache
                        hit1=0;     //Not found in L1 Cache
                        Wait=0;      //We have found the required data ... so the process is complete and controller is ready for next input
                        l2_cache_memory[l2_index][(l2_checka*l1_block_bit_size+(offset+1)*byte_size-1)-:byte_size]=stored_data;     //modify the data at address to input data
                    end
                end
                if (dummy_hit_w==0)         //if still the address was not found, we start searching in main memory
                begin
                    hit1=0;     //Not found in L1 Cache
                    hit2=0;     //Not found in L2 Cache
                    if(main_memory_delay_counter_w < main_memory_latency)      //implementing the delay due to searching in main memory by running a counter
                    begin
                        main_memory_delay_counter_w=main_memory_delay_counter_w+1;  //incrementing the counter variable in each cycle
                        Wait=1;         //still the search is going on and the processor needs to wait before giving another input
                        is_L2_delay_w=1;    //No need to again check in L2 in next delay cycle in this counter
                    end
                    else
                    begin
                        main_memory_delay_counter_w=0;  //reset the main memory delay counter for next input
                        Wait=0;       //so controller is ready for next instruction
                        is_L2_delay_w=0;        //Check in L2 as well for next input 
                        main_memory[main_memory_blk_id][((offset+1)*byte_size-1)-:byte_size]=stored_data;       //modify the data in the given location in main memory
                    end
                end
            end /*searching in L2 and Main ends here */
        end    /*else not found in L1 ends here*/
    end
end
endmodule