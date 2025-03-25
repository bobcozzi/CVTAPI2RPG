<h2>Convert C typedef structs to RPG IV DCL-DS</h2>
<p>The CVTAPI2RPG command reads the QSYSINC/H "header" files that contain IBM i API structures. It converts those structures to RPG IV DCL-DS data structure declarations with subfields to the best of its ability.</p>
<p>To download the compiled version and the source, you can click the "Release" link on the right of this page.</p>
<p>The input and output source files and member names are user specified so you can read from any source file and write to any source file.</p>
<p>For example, if you want an RPG IV version of the data structure returned by the Retrieve User Space Attributes (QUSRUSAT) API you could run the following:</p>
<pre>CVTAPI2RPG FROMMBR(QUSRUSAT) TOFILE(RPGFREE/QCPYSRC) CRTMBR(*YES) TYPEDEF(*ALL)</pre>
<p>This searches QUSRUSAT memeber in the H file in QSYSINC for any typedef statements and converts them to RPG IV DCL-DS statements.
That QUSRUSAT member in H in QSYSINC contains only one typedef, and that typedef looks like this:</p>
<pre>typedef _Packed struct Qus_SPCA_0100 {        
     int    Bytes_Returned;                   
     int    Bytes_Available;                  
     int    Space_Size;                       
     char   Automatic_Extendability;          
     char   Initial_Value;                    
     char   Library_Name[10];                 
} Qus_SPCA_0100_t;</pre>

<p>The CVTAPI2RPG command will read that C code and convert it to the following RPG IV code:</p>
<pre> // Converted from: &lt;QSYSINC/H/QUSRUSAT&gt;             
dcl-ds Qus_SPCA_0100_T  Qualified Inz TEMPLATE;       
  Bytes_Returned INT(10);                             
  Bytes_Available INT(10);                            
  Space_Size INT(10);                                 
  Automatic_Extendability CHAR(1);                    
  Initial_Value CHAR(1);                              
  Library_Name CHAR(10);                              
end-ds;  // Qus_SPCA_0100_T</pre>
<p>Note that User Space attributes (i.e., Qus_SPCA_0100_T) is one of the few typedef/structure names that breaks the format ID number (e.g., 0100) from the format code (e.g., "SPCA"). Virtually all other APIs use formatting names that look like this pattern:  Qxx_FFFFnnnn Where xx is the app ID, FFFF is the identifier/API ID, and nnnn is a 4-digit sequence nunber.</p>
<h3>Standard RPG IV API Structure</h3>
<p>Since the structures returned by system APIs in the H file in the QSYSINC library for the C and C++ languages are critical, and are used by IBM in some cases, they are always well maintained. Their RPG version can be a little neglected as they still use fixed format, and short 6-char names. In some cases, the legacy "B" datatype is still used. The only exceptions are the IFS prototypes in QRPGLESRC(IFS) IBM actually maintains those very well.</p><p>Here is what the RPG IV version of the IBM-supplied QUS_SPCA_0100_T data structure looks like today:</p>
<pre>
DQUSA0100         DS                                                   
D*                                             Qus SPCA 0100           
D QUSBRTN05               1      4I 0                                  
D*                                             Bytes Returned          
D QUSBAVL06               5      8I 0                                  
D*                                             Bytes Available         
D QUSSS                   9     12I 0                                  
D*                                             Space Size              
D QUSAE                  13     13                                     
D*                                             Automatic Extendability 
D QUSIV                  14     14                                     
D*                                             Initial Value           
D QUSLIBN02              15     24                                     
D*                                             Library Name                 
</pre>
<h3>Best Practices</h3>
<p>The CVTAPI2RPG command can read C typedef structures that IBM provides and translate them to free-format RPG IV that can be used with API calls from within RPG.</p><p>Field names in the typedefs are ported directly from C to RPG IV so you get more descriptive names. When nested data structures are detected, it will insert a LIKEDS in the RPG code and reference the nested structure. Therefore, it may be best to identify the C source member in the H file in QSYSINC and then specify TYPEDEF(*ALL) on the command. That way you get all related structures that the subsequent typedefs may be using. For example, the Retrieve Job Attributes API named QUSRJOBI format JOBI0600 contains the group profile names as an array.</p>
<h4>Why not also convert C prototypes to RPG IV?</h4>
<p>A common trend among programmers who started coding in the 1990s or later is to omit parameter names in function prototypes. While this practice can reduce clarity and maintainability, (I consider it lazy) it has become widespread, including in the IBM i QSYSINC System API prototypes. Unfortunately, this pervasiveness makes it impractical to directly convert C prototypes to RPG IV with any level of clarity.</p>

