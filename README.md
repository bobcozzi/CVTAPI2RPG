Convert C typedef structs to RPG IV DCL-DS
The CVTAPI2RPG command reads the QSYSINC/H "header" files that contain IBM i API structures. It converts those structures to RPG IV DCL-DS data structure declarations with subfields to the best of its ability.
The input and output source files and member names are user specified so you can read from any source file and write to any source file.
For exampe, if you want an RPG IV version of the data structure returned by the Retrieve User Space Attributes API (QUSRUSAT) you could run the following:
'CVTAPI2RPG FROMMBR(QUSRUSAT) TOFILE(RPGFREE/QCPYSRC) CRTMBR(*YES) TYPEDEF(*ALL)'
This searches QUSRUSAT memeber in the H file in QSYSINC for any typedef statements and converts them to RPG IV DCL-DS statements.
The QUSRUSAT member contains only one typedef, and that typedef looks like this:
<pre>typedef _Packed struct Qus_SPCA_0100 {        
     int    Bytes_Returned;                   
     int    Bytes_Available;                  
     int    Space_Size;                       
     char   Automatic_Extendability;          
     char   Initial_Value;                    
     char   Library_Name[10];                 
} Qus_SPCA_0100_t;</pre>

The generated RPG IV Code is:
<pre> // Converted from: <QSYSINC/H/QUSRUSAT>             
dcl-ds Qus_SPCA_0100_T  Qualified Inz TEMPLATE;       
  Bytes_Returned INT(10);                             
  Bytes_Available INT(10);                            
  Space_Size INT(10);                                 
  Automatic_Extendability CHAR(1);                    
  Initial_Value CHAR(1);                              
  Library_Name CHAR(10);                              
end-ds;  // Qus_SPCA_0100_T</pre>

