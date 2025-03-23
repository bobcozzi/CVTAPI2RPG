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

<h3>Best Practices</h3>
<p>Since the API return templates in the QSYSINC library for the C and C++ languages are critical, they are always kept up to date. The RPG stuff is kind of a less usable attempt at a similar set of structures.</p><p>Now, the CVTAPI2RPG command can read hose C typedef structures that IBM provides, and translate them to free-format RPG IV that can be used with API calls from within RPG.</p><p>Field names in the typedefs are ported directly to RPG IV so you get the same somewhat descriptive names found in C, but in RPG IV.</p><p>Note that it is often best to just get *ALL typedefs at one for a particular memeber as determining the name for one vs another can be inconsistent and time-consuming. So I recommend that when you need a structure for an API, such as the Retrieve Object Description (QUSROBJD) API, you just get TYPEDEF(*ALL) instead of looking for a specific structure. It is ia future objective to add better search capabilities to the TYPEDEF parameter of the CVTAPI2RPG command. But for now, an exact match is required.</p><p>For example:</p>
<pre>CVTRPG2API FROMFILE(QSYSINC/H) FROMMBR(QUSROBJD) TOFILE(<yourlib>/QRPGLESRC) TOMBR(QUSROBJD) CRTMBR(*YES) TYPEDEF(Qus_OBJD0100)</pre>
This retrieves only the typedef for QUSROBJD API format OBJD0100. To get all the OBJD0x00 formats specify TYPEDEF(*ALL).
