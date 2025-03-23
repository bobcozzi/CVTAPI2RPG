**FREE
        ctl-opt OPTION(*NODEBUGIO: *SRCSTMT) FIXNBR(*ZONED)
                COPYRIGHT('(c) 2025 by R. Cozzi, Jr. All rights reserved.')
                MAIN(MAIN);

        /include rpgfree/qcpysrc,rpgt_const
        /include rpgfree/qcpysrc,rpgt_srcfT

          // Define the input and output source files
          // Both files:
          //   User-controled Open
          //   Runtime (pre-Open) File, library and Member names
          dcl-F QSRCFIN LIKEFILE(QSRCFIN_T)
                       INFDS(inSRCINFDS)
                       USROPN EXTFILE(INSRCF) EXTMBR(INMBR);

            // The output file is declare as I/O
            // This allows the program to read the last source
            // sequence number from the member in order
            // to increment it for newly added source records.
          dcl-F QSRCFOUT DISK(MAX_SRCFILE_LEN)
                       USAGE(*INPUT : *OUTPUT) INFDS(outSRCINFDS)
                       USROPN EXTFILE(OUTSRCF) EXTMBR(OUTMBR);

          /include rpgfree/qcpysrc,rpgt_srcrc
          /include rpgfree/qcpysrc,rpgt_infds
          /include rpgfree/qcpysrc,rpgt_proto

            // Most API includes for the C/C++ language
            // are stored in library QSYSINC in source file H
            // The API structures are usually but not always
            // stored in a member named the same as the API.
          DCL-S INSRCF VARCHAR(21) INZ('QSYSINC/H');
          DCL-S INMBR  CHAR(10) INZ('*FIRST');


            // Users of the CVTAPI2RPG CL command should
            // specify the RPG IV source output file and member.
            // The default I've established is QCPYSRC in library RPGFREE.
            // For the member name, I use the special value *FROMMBR.
            // This allows the program to use the input member name.
          DCL-S OUTSRCF VARCHAR(21) INZ('RPGFREE/QCPYSRC');
          DCL-S OUTMBR  CHAR(10) INZ('*FROMMBR');

            // The inSRCINFDS structure is the input file's INFDS.
            // It allow us to access the File's actual record length,
            // the number of records in the file, along with
            // the runtime source file, library and member name
            // that were opened.
          DCL-DS inSRCINFDS LIKEDS(SRCINFDS_T);

            // The SRCFOUTDS structure is the output file's INFDS.
            // It has the same structure as the Input File's inSRCINFDS
            // the number of records in the file, along with
            // the runtime source file, library and member name
            // that were opened.
          DCL-DS outSRCINFDS LIKEDS(SRCINFDS_T);
          // end-DS;

          // The program-described input and output files'
          // record format is a standard IBM i Source Physical File
          // It contains a sequence number zoned(6, 2)
          // a source statement change date zoned(6, 0)
          // and the source statement data char(*)
          // I've settled on a maximum source statement length of 228
          // to suppor the so called "SEU Max file length" of 240 bytes.
          // If you routinely have longer source record lengths,
          // then change the MAX_SRCLINE_LEN cosntant along with
          // the MAX_SRCFILE_LEN const record length used on
          // the DCL-F statements.
          dcl-ds inSRCRCD  LIKEDS(SRCRCD_T) Inz;
          dcl-ds outSRCRCD LIKEDS(SRCRCD_T) Inz;

          dcl-pr system int(10) extproc('system');
            clCmd pointer value options(*string);
          end-pr;
          dcl-s rc int(10);
          dcl-s typedef varchar(128);
          dcl-s typedefName varchar(128);
          dcl-s typeDefCount int(5);
          dcl-s bCrtNewMbr ind inz(*off);
          dcl-s bDataOpt ind inz(*off);
          dcl-s bFileEOF ind inz(*off);
          dcl-s clCMD varchar(256);
          dcl-s line varchar(MAX_SRCLINE_LEN);
          dcl-s fieldName varchar(128);
          dcl-s fieldType varchar(128);
          dcl-s fieldSize  int(5);
          dcl-s fieldDec   int(5);
          dcl-s blanks10 char(10) inz(' ');
          dcl-s blanks12 char(12) inz(' ');

          Dcl-S srcLine     varchar(MAX_WORKSRC_LEN);
          Dcl-S srcCmt      varchar(MAX_WORKSRC_LEN);
          dcl-s bEOF          ind inz(*off);
          dcl-s bInsideStruct ind INZ(*OFF);
          dcl-s bEmbedStruct  ind INZ(*OFF);

    dcl-proc main;
      dcl-pi main;
          inSrcFile  char(20) const;  // Input source file
          inSrcMbr   char(10) const;  // Input source member
          outSrcFile char(20) const;  // Output source file
          outSrcMbr  char(10) const;  // Output source member
          CRTMBR     int(5) const;  // Create member if not found (0=No, 1=Yes)
          DTAOPT     int(5) const;  // Data option (0=Add, 1=Replace)
          typeDef_ID varchar(128) const;  // TypeDef to convert  or *ALL
      end-pi;

      inSRCF =  %trimr(%SUBST(inSrcFile:11 : 10)) + '/' +
                %trimr(%SUBST(inSrcFile: 1 : 10));
      inMBR = inSrcMbr;
      outSRCF = %trimr(%SUBST(outSrcFile:11 : 10)) + '/' +
                %trimr(%SUBST(outSrcFile:1 : 10));

      outMBR = outSrcMbr;
      typedef = %lower(typeDef_ID);

      if (outMBR = '*FROMMBR');
        outMBR = inMBR;
      endif;

      open(e) QSRCFIN;
      if %error();
        snd-msg 'Failed to open input file ' + inSRCF + ' ' + inMBR;
        return;
      endif;

      if (CRTMBR <> 0);        // Create the output member
        clCMD = 'ADDPFM FILE(' + %trim(outSRCF) + ') ' +
                ' MBR(' + %trim(outMBR) + ') ' +
                ' SRCTYPE(RPGLE)';
        monitor;
          rc = system(clCMD);
        on-error;
          close(e) QSRCFIN;
          close(e) QSRCFOUT;
          snd-msg 'Failed to create output member ' + outMBR;
          return;
        endmon;
      endif;

      if (DTAOPT <> 0);        // Clear the output member
        clCmd = 'CLRPFM FILE(' + %trim(outSRCF) + ') MBR(' + %trim(outMBR) + ')';
        monitor;
          rc = system(clCmd);
        on-error;
          snd-msg 'Failed to clear output member ' + outMBR + ' in ' + outSRCF +
            ' Continuing...';
        endmon;
      endif;

      open(e) QSRCFOUT; // Open the output file and member

      if %error();
        close(e) QSRCFIN;
        close(e) QSRCFOUT;
        snd-msg 'Failed to open output file ' + outSRCF + ' ' + outMBR;
        return;
      endif;

    dou ((%eof(QSRCFIN) or bEOF) or %lower(typedef) <> '*all');
      bEOF = readCStmt(QSRCFIN : inSRCINFDS.rcdLen : srcLine : srcCmt);
      // read(e) QSRCFIN inSRCRCD;
        // Search the input source member for the typedef
      dow not (%eof(QSRCFIN) or bEOF);
        // line = %trim(%SUBST(inSRCRCD.srcdata : 1 :inSRCINFDS.rcdLen-12));
        line = srcLine;
        if (%len(line) >= 7 and %subst(line: 1: 7) = 'typedef'); // starts with typedef?
          typedefName = extractTypedefName(line);
          if (typedef = '*all' or typedef = %lower(typedefName));
            if parseTypedef(line : line);
              writeSrcRcd(line);
            else;
              bInsideStruct = *on;
              typeDefCount += 1;
              leave;
            endif;
          endif;
        endif;
        bEOF = readCStmt(QSRCFIN : inSRCINFDS.rcdLen : srcLine : srcCmt);
      enddo;
      bFileEOF = %eof();  // debug purposes only

      if bEOF or not bInsideStruct;
        close(e) QSRCFIN;
        close(e) QSRCFOUT;
        if (typeDefCount = 0);
          snd-msg 'Failed to find typedef ' + typedef;
        endif;
        return;
      endif;

      // Now read the structure fields
      outSRCRCD.srcSeq = 0;

      // Loop through lines to read struct members
      bEOF = readCStmt(QSRCFIN : inSRCINFDS.rcdLen : srcLine : srcCmt);
      // read(e) QSRCFIN inSRCRCD; // Read next line

      processStruct(typedefName);

      if (outSRCRCD.srcSeq > 0);
        writeSrcRcd(blanks10 + 'end-ds; ' +
                ' // ' + typedefName + '_T');
      endif;
    enddo;  // End DO TypeDef = *ALL

    close(e) QSRCFIN;
    close(e) QSRCFOUT;

    end-proc;


// Example procedures (to be defined as per your needs)

// Procedure to extract typedef name
dcl-proc extractTypedefName;
  dcl-pi extractTypedefName varchar(128) rtnparm;
    line varchar(MAX_SRCLINE_LEN) const;
  end-pi;
  dcl-c cTypedef Const('typedef ');
  dcl-c cStruct  Const('struct ');
  dcl-c cPacked  Const('_Packed ');

  dcl-s td int(5);
  dcl-s pd int(5);
  dcl-s st int(5);
  dcl-s tSize int(5);

  dcl-s start int(5);

  td = %scan(cTypeDef : line);
  pd = %scan(cPacked : line);
  st = %scan(cStruct : line);

  start = td;
  tSize = %size(cTypedef);
  if (pd > start);
    start = pd;
    tSize = %size(cPacked);
  endif;
  if (st > start);
    start = st;
    tSize = %size(cStruct);
  endif;
  if (start = 0);
    return '';
  endif;

  // Code to extract the typedef name from the line
  return %trim(%SUBST(line : start+tSize) : '{} ;'); // Get typedef name

end-proc;

// Procedure to extract typedef name
dcl-proc isEmbeddedStruct;
  dcl-pi isEmbeddedStruct ind rtnparm;
    line varchar(MAX_SRCLINE_LEN) const;
  end-pi;

  dcl-c cTypedef Const('typedef ');
  dcl-c cStruct  Const('struct ');
  dcl-c cPacked  Const('_Packed ');

  dcl-s td int(5);
  dcl-s pd int(5);
  dcl-s st int(5);

  td = %scan(cTypeDef : line);
  pd = %scan(cPacked : line);
  st = %scan(cStruct : line);
  if (td = 1 or pd = 1 or st = 1);
    return *on;
  endif;
  return *OFF;
end-proc;

// Procedure to extract the field type from the line
dcl-proc extractFieldType;
  dcl-pi extractFieldType varchar(128) rtnparm;
    line varchar(MAX_SRCLINE_LEN) const;
  end-pi;

  dcl-s rpgType varchar(128);

  dcl-s endOfType int(5);
  dcl-s lineLen int(5);
  dcl-s cType varchar(128);
  dcl-s cName varchar(128);
  dcl-s cSize varchar(32);
  dcl-s state int(5) inz(0);
  dcl-s fieldType varchar(128);

  dcl-s isStruct ind inz(*off);
  dcl-s isPacked ind inz(*off);
  dcl-s token varchar(MAX_SRCLINE_LEN);

  lineLen = %len(%TrimR(line));
  if (lineLen > 0);
    endOfType = %ScanR(' ' : line : 1 : lineLen);  // Find last non-blank after datatype
  endif;
  if (endOfType = 0);
    return '';
  endif;
  fieldType = %trimR(%SUBST(line: 1: endOfType)); // Extract the type

  if (%len(fieldType) >= 2 and
      (%SUBST(fieldType : 1 : 2) = '/*' or
       %SUBST(fieldType : 1 : 2) = '//'));
    rpgType = '  //  ' + fieldType;
  elseif (%len(fieldType) >= 1 and
          %SUBST(fieldType : 1 : 1) = '}');
    rpgType = '  //  ' + fieldType;
  endif;
  if (rpgType <> '');  // Is it a comment?
    return rpgType;
  endif;

  fieldType += ' ';  // Add a space to the end

 // Loop through each token to find the length (array [n] length, if any)
   for-each token in %split(line : '[{} ;');
      if (%subst(token : %len(token)) = ']');
         token = %TRIM(token : ';[{}] ');
         cSize = token;
         leave;
      endif;
    endfor;

    if (%scan('long long ' : fieldType) > 0);
      rpgType = 'INT(20)';
    elseif (%scan('long ' : fieldType) > 0);
      rpgType = 'INT(10)';
    elseif (%scan('int ' : fieldType) > 0);
      rpgType = 'INT(10)';
    endif;
    if (%scan('short ' : fieldType) > 0);  // "short int" or "short" replaced INT(10) w/INT(5)
      rpgType = 'INT(5)';
    endif;
    if (%scan('Decimal' : fieldType) > 0);
      rpgType = %scanRPL('_Decimal': 'Packed' : fieldType);
      rpgType = %scanRPL(',': ' : ' : rpgType);
    endif;

  if (%scan('unsigned ' : fieldType) > 0);
    rpgType = %scanRPL('INT': 'UNS' : rpgType);
  endif;

  if (rpgType = '');  // Is still empty?
    if (%scan('char' : fieldType) > 0);
      if (cSize = '');
        cSize = '1';
      endif;
      rpgType = 'CHAR(' + cSize + ')';
    else;

      if (%len(fieldType) > 1 and %subst(fieldType: 1: 1) = '_' and
          %scan('Decimal' : fieldType) = 0);
          rpgType = 'Q' + %trim(fieldType);  // Accomodate struct types
      else;
        rpgType = fieldType;
      endif;
      rpgType = 'LIKEDS(' + rpgType + ')';
    endif;
  endif;


  return rpgType;

end-proc;

// Procedure to extract the field name from the line
dcl-proc extractFieldName;
  dcl-pi extractFieldName varchar(128) rtnparm;
    line  varchar(MAX_SRCLINE_LEN) const;
    fieldLen int(5);
    fieldDec int(5);
  end-pi;

  dcl-s startOfName int(5);
  dcl-s fieldName varchar(128);
  dcl-s fieldSize varchar(128);
  dcl-s strPos int(5);
  dcl-s endPos int(5);

  fieldLen = 0;
  fieldDec = 0;


  if (%len(line) >= 2 and
      (%SUBST(line : 1 : 2) = '/*' or
       %SUBST(line : 1 : 2) = '//'));
    return '';
  endif;

  endPos = %checkR('; ,' : line); // Find the end of field type
  if (endPos = 0);
    return '';
  endif;

  startOfName = %scanR(' ' : line : 1 : endPos);  // Find first position of field name
  if (startOfName > 0);
    fieldName = %trim(%SUBST(line: startOfName + 1)); // Extract the name
  else;
    return '';
  endif;

  if (%len(fieldName) >= 2 and %subst(fieldName: 1 : 2) = '//');
    return '';
  endif;

  fieldName = %trimR(fieldName : ' ; '); // Remove trailing spaces and semicolon
  strPos = %scan('[' : fieldName);       // Find the start of array size (if any)
  if (strPos = 0);
    return %trimR(fieldName : '[;] ');
  endif;

  if (strPos > 0);
    endPos = %scan(']' : fieldName); // Find the end of array size
    fieldSize = %SUBST(fieldName : strPos + 1 : endPos - strPos - 1); // Extract array size
    if (%scan(',' : fieldSize) > 0);
      fieldLen = %int(%trim(%SUBST(fieldSize: 1: %scan(',' : fieldSize) - 1))); // Extract length
      fieldDec = %int(%trim(%SUBST(fieldSize: %scan(',' : fieldSize) + 1))); // Extract decimal
    else;
      fieldLen = %int(%trim(fieldSize));
      fieldDec = -1;
    endif;
  endif;

  return %SUBST(fieldName : 1 : strPos - 1);
end-proc;

dcl-proc processStruct;
    dcl-pi processStruct;
      typedefName varchar(128) const;
    end-pi;

      dow (bInsideStruct and not (%eof(QSRCFIN) or bEOF));
        line = srcLine;
     //   line = %trim(inSRCRCD.srcData);  // Need left and right trim
          if isEmbeddedStruct(line);
            line = removeEmbeddedStruct(line);
            bEmbedStruct = *on;
          elseif (bEmbedStruct);
            if (%scan('}' : line) > 0);
              bEmbedStruct = *off;
              clear line;
            endif;
          endif;
          if (%len(line) > 0);
          // check for EOF
          // EOF = "} typedefName_T;"
            line = removeComments(line); // Remove comments
          endif;
          if (%len(line) > 0);
            if (%subst(LINE : 1 : 1) = '}' and
                (%scan(%lower(typedefname) + '_t' : %lower(line)) > 0 or
                %scan(%lower(typedefname) : %lower(line)) > 0));
              // End of this typedef struct definition
              bInsideStruct = *off;
            elseif (%subst(LINE : 1 : 1) = '{'); // Skip start of typedef on its own
              // Just skip it
            else;

              // Process each struct member line
              fieldType = extractFieldType(line); // Custom procedure to get field type
              fieldName = extractFieldName(line : fieldsize : fieldDec); // Get Field Name/Size
              if (%scan('CHAR' : fieldType) > 0);  // If CHAR, then set the field length
                if (fieldSize <= 0);
                  fieldSize = 1;
                endif;
                fieldType = %ScanRPL('?' : %char(fieldSize) : fieldType);
              endif;
              if (outSRCRCD.srcSeq = 0);  // First record?
                SETLL *END QSRCFOUT;
                readP qsrcfout outSRCRCD;
                if %EOF();  // Nothing in the file? Then use 0
                  outSRCRCD.srcSeq = 0;
                endif;
                writeSrcRcd('');

                writeSrcRcd( blanks12 + '// Converted from: <' +
                              %trimR(inSRCINFDS.rt_Library) + '/' +
                              %trimR(inSRCINFDS.rt_FileName) + '/' +
                              %trimR(inSRCINFDS.rt_Mbr) + '>');
                writeSrcRcd(blanks10 + 'dcl-ds ' +
                              typedefName + '_T ' +
                              ' Qualified Inz TEMPLATE;'); // Start of struct
              endif;

              // Convert the field type to RPG
              outSRCRCD.srcData = blanks12 + fieldName + ' ' + fieldType + ';';
              outSRCRCD.srcDate = %dec( %date() : *YMD);
              outSRCRCD.srcseq += 1;
              write(e) QSRCFOUT outSRCRCD;
              if (%len(%TRIMR(outSRCRCD.srcData)) > outSRCINFDS.rcdLen - 12);
                snd-msg 'WARNING! Line ' + %char(outSRCRCD.srcseq) +
                    ' too long for output source file member.';
              endif;
            endif;
        endif;
        // read(e) QSRCFIN inSRCRCD; // Read next line
        bEOF = readCStmt(QSRCFIN : inSRCINFDS.rcdLen : srcLine : srcCmt);

      enddo;
  end-proc;

  dcl-proc removeEmbeddedStruct;
    dcl-pi removeEmbeddedStruct varchar(MAX_SRCLINE_LEN) rtnparm;
      line varchar(MAX_SRCLINE_LEN) const;
    end-pi;

    dcl-s strPos int(5);
    dcl-s endPos int(5);

  dcl-c cTypedef Const('typedef ');
  dcl-c cStruct  Const('struct ');
  dcl-c cPacked  Const('_Packed ');

  dcl-s td int(5);
  dcl-s st int(5);
  dcl-s pd int(5);

    if (%len(line) < 2);
      return line;
    endif;

  td = %scan(cTypeDef : line);
  if (td > 0);
    strPos = td;
    endPos = td + %size(cTypedef)-1;
  endif;

  pd = %scan(cPacked : line);
  if (pd > 0);
    strPos = %MIN(%max(1:strPos) : pd);
    endPos = %MAX(endPos : pd + %size(cPacked) - 1);
  endif;
  st = %scan(cStruct : line);
  if (st > 0);
    strPos = %MIN(%max(1:strPos) : st);
    endPos = %max(endPos : st + %size(cStruct) - 1);
  endif;
  if (strPos > 0 and endPos > 0);
    endPos = %max(endPos : %scan('{' : line));
  endif;
  if (strPos > 0 and endPos > strPos);
    if (strPos + endPos > %len(line));
      return '';
    else;
      return %TRIML(%SUBST(line : strPos + endPos));
    endif;
  endif;
  return line;
end-proc;

  dcl-proc removeComments;
    dcl-pi removeComments varchar(MAX_SRCLINE_LEN) rtnparm;
      line varchar(MAX_SRCLINE_LEN);
    end-pi;
    dcl-s strPos int(5);
    dcl-s endPos int(5);

    if (%len(line) < 2);
      return line;
    endif;
    strPos = %scan('/*' : line);
    if (strPos = 0);
      strPos = %scan('//': line);
    endif;
    if (strPos = 0);
      return line;
    endif;
    endPos = %scan('*/' : line : strPos);
    if (endPos = 0);
      if (strPos <= 1);
        return '';
      else;
        return %trim(%SUBST(line : 1 : strPos - 1));
      endif;
    endif;
    if (strPos > 1 and endPos > strPos);
      if (endPos + 2 < %len(line));
        endPos += 2;
      else;
        %SUBST(line : endPos) = '  ';  // clear everything after end of comment
      endif;
      line = %trim(%SUBST(line : 1 : strPos - 1)) +
             %trim(%SUBST(line : endPos));
    endif;
    return %trimL(line);
  end-proc;

 dcl-proc parseTypedef;
   dcl-pi parseTypedef IND;
      typedefLine char(MAX_SRCLINE_LEN) const; // Input C typedef line
      RPGDCL varchar(MAX_SRCLINE_LEN);  // RPG DCL-S statement
   end-pi;

    dcl-s token varchar(MAX_SRCLINE_LEN);
    dcl-s cType varchar(MAX_SRCLINE_LEN);
    dcl-s cName varchar(MAX_SRCLINE_LEN);
    dcl-s rpgType varchar(MAX_SRCLINE_LEN);
    dcl-s state int(10) inz(0);
    dcl-s tSize varchar(MAX_SRCLINE_LEN);
    dcl-s isTypeDef ind inz(*off);
    dcl-s isPacked ind inz(*off);
    dcl-s isStruct ind inz(*off);

   // Loop through each token in the typedef statement
   for-each token in %split(typedefLine : '[ ;');
      if (%subst(token : %len(token)) = ';');
         token = %TRIMR(token : '; ');
      endif;
      if (%subst(token : %len(token)) = ']');
         token = %TRIM(token : ';[] ');
         tSize = token;
      endif;
      select;
         when state = 0 and token = 'typedef';
            state = 1; // Found typedef, move to next token
            isTypeDef = *on;

         when token = 'struct';
            isStruct = *on; // If typedef _Packed struct then bail out

         when token = '_Packed';
            isStruct = *on; // If typedef _Packed struct then bail out
            isPacked = *on;

         when state = 1;
          if token = 'unsigned' or token = 'signed';
            cType = token + ' '; // Store it and wait for the next part
          elseif isStruct;
            cName = %TRIMR(token : '{}');
            state = 2;
          else;
            cType += %TRIMR(token : '{}');
            state = 2; // Captured type, expect variable name next
          endif;
         when state = 2 and token <> ';' and token <> '{';
            cName = %TRIMR(token : '{}');
            state = 3; // Captured variable name
      endsl;

   endfor;

    // If a struct typedef is detected, bail out
    if ((isTypeDef and isStruct) or (cType = '' and cName = ''));
        rpgDCL = %TRIMR(cName : '{}');
        return *off;
    endif;

    if (%scan('long long ' : cType) > 0);
      rpgType = 'INT(20)';
      if (tSize <> '');
        rpgType += ' DIM(' + tSize + ')';
      endif;
    elseif (%scan('long ' : cType) > 0);
      rpgType = 'INT(10)';
      if (tSize <> '');
        rpgType += ' DIM(' + tSize + ')';
      endif;
    elseif (%scan('int ' : cType) > 0);
      rpgType = 'INT(10)';
      if (tSize <> '');
        rpgType += ' DIM(' + tSize + ')';
      endif;
    endif;
    if (%scan('short ' : cType) > 0);
      rpgType = 'INT(5)';
      if (tSize <> '');
        rpgType += ' DIM(' + tSize + ')';
      endif;
    endif;
    if (%scan('unsigned' : cType) > 0);
      rpgType = %scanRPL('INT': 'UNS' : rpgType);
    endif;
    if (rpgType = '');  // Is still empty?
      if (%scan('char' : cType) > 0);
        rpgType = 'CHAR(' + tSize + ')';
      else;
        if (%len(cType) > 1 and %subst(cType: 1: 1) = '_');
            rpgType = 'Q' + %trim(cType);  // Accomodate struct types
        else;
          rpgType = cType;
        endif;
      endif;
    endif;
   // Map C types to RPG equivalents

   // Generate RPG DCL-S statement
   rpgDcl = 'dcl-s ' + cName + ' ' + rpgType + ';';
   return *ON;
end-proc;

    dcl-proc writeSrcRcd;
      dcl-pi writeSrcRcd;
        line varchar(MAX_SRCLINE_LEN) const;
      end-pi;

      outSRCRCD.srcData = line;
      outSRCRCD.srcDate = %dec( %date() : *YMD);
      outSRCRCD.srcSeq += 1;
      write(e) QSRCFOUT outSRCRCD;
      if (%len(%TRIMR(outSRCRCD.srcData)) > outSRCINFDS.rcdLen - 12);
        snd-msg 'WARNING! Line ' + %char(outSRCRCD.srcseq) +
            ' too long for output source file member.';
      endif;

    end-proc;