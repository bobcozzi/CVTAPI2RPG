**FREE
        ctl-opt OPTION(*NODEBUGIO: *SRCSTMT) FIXNBR(*ZONED)
                COPYRIGHT('(c) 2025 by R. Cozzi, Jr. All rights reserved.')
                NOMAIN;

        /include rpgfree/qcpysrc,rpgt_const
        /include rpgfree/qcpysrc,rpgt_srcFT
        /include rpgfree/qcpysrc,rpgt_INFDS
        /include rpgfree/qcpysrc,rpgt_srcRC

        Dcl-S srcLine     Varchar(MAX_WORKSRC_LEN);
        Dcl-S srcBuffer   Varchar(MAX_WORKSRC_LEN);
        Dcl-S srcCmt      Varchar(MAX_WORKSRC_LEN);


        dcl-proc readCStmt EXPORT;
        dcl-pi   readCStmt ind EXTPROC('readCStmt');  // Reutrn Indy is EOF flag
            inSrcFile  LIKEFILE(QSRCFIN_T);
            rcdLen     int(10) Const;
            srcStmt    varCHAR(MAX_WORKSRC_LEN);
            Comments   varCHAR(MAX_WORKSRC_LEN);
        end-pi;
        dcl-s src_EOF IND INZ(*OFF);

   Dcl-S nCondLevel int(5) Inz(0);
   Dcl-S InComment Ind Inz(*Off);   // Track block comments /* ... */
   Dcl-S bLineCmt  Ind Inz(*OFF);
   Dcl-S InQuote   Ind Inz(*Off);   // Track quoted strings
   Dcl-S bGuard    Ind Inz(*Off);   // Track #ifndef guard
   Dcl-S nGuard    Int(5) Inz(0);   // Track #ifndef guard level
   Dcl-S QuoteChar Char(1);         // Type of quote (' or ")
   Dcl-S StmtComplete Ind Inz(*Off);
   Dcl-S Pos Int(10);
   Dcl-S CH Char(1);
   Dcl-S srcLen int(5);
   Dcl-ds srcrcd likeDS(SRCRCD_T) Inz;

      clear srcStmt;
      clear Comments;
      clear srcCmt;
      clear srcLine;
      clear srcBuffer;
      clear src_EOF;
      clear QuoteChar;
      clear Pos;
      clear CH;

   DoU stmtComplete;
      read inSrcFile srcRcd;
      If %Eof();
         src_EOF = *ON;
        Leave;
      EndIf;
      bLineCmt = *OFF;

      // Remove leading/trailing spaces
      srcBuffer = %TRIM(%SUBST(srcRcd.srcdata : 1 : rcdLen-12));
      if (%len(srcBuffer) = 0);
         Iter; // Skip empty lines
      endif;
      srcLen = %len(srcBuffer);
      if (srcLen > 3);
         if (bGuard);
            if (srcLen > 5 and %Subst(srcBuffer : 1 : 6) = '#endif');
               nGuard -= 1;
            elseif (srcLen > 7 and %Subst(srcBuffer : 1 : 7) = '#define');
               if (bGuard);
                  nGuard += 1;
                  iter;
               endif;
            endif;
            bGuard = *OFF;
         else;
            if (srcLen > 7 and %Subst(srcBuffer : 1 : 7) = '#ifndef');
               If NOT bGuard;
                  bGuard = *ON;
                  iter;
               endif;
            endif;
         endif;
         if (srcLen > 3 and %Subst(srcBuffer : 1 : 3) = '#if');
            if (bGuard and nGuard > 0 or
                not bGuard);
               nCondLevel += 1;
            endif;
         elseif (srcLen > 5 and %Subst(srcBuffer : 1 : 6) = '#endif');
            nCondLevel -= 1; // Decrement the level
            Iter; // Skip this line if inside a #if block
         endif;
      endif;
      if (nCondLevel > 0 and nCondLevel > nGuard);
         Iter; // Skip this line if inside a #if block
      endif;
      if (srclen > 0 and %SUBST(SRCBUFFER : 1 : 1 ) = '#');
         // just another directive? Then skip it
         iter;
      endif;

      // Process each character in the line one-by-one
      For POS = 1 TO srcLen;
         CH = %Subst(srcBuffer : Pos : 1);

         // Toggle quote tracking when encountering ' or ", but ignore escaped quotes (\")
         If (CH = '''' Or CH = '"') And (Pos = 1 Or %Subst(srcBuffer: Pos-1:1) <> '\');
            If InQuote And QuoteChar = CH;
               InQuote = *Off; // Closing quote
            ElseIf Not InQuote;
               InQuote = *On;
               QuoteChar = CH; // Opening quote
            EndIf;
         EndIf;
            // Handle line comment type '//'
         If (pos+1 <= srclen) and
            (Not InQuote) and
            (Not InComment);
            If (%Subst(srcBuffer : Pos : 2) = '//');
               bLineCmt = *ON;
               srcCmt += %Subst(srcBuffer : Pos);  // Everything after // is the comment
               Leave;  // Stop processing further (rest of the line is a comment)
            EndIf;
         EndIf;

         // Handle block comments (/* ... */)
         If  pos+1 <= srcLen and Not InQuote;
            If (%Subst(srcBuffer : Pos : 2) = '/*');
               InComment = *ON;
            EndIf;
         EndIf;

         If InComment;
            If (%Scan('*/' : srcBuffer) > 0 and NOT bLineCmt);
               inComment = *OFF;
            endif;
            leave;
         EndIf;

          // Accumulate non-commented parts of the line
         If Not InComment;
            srcLine += CH;
         EndIf;
      EndFor;

      // Check if the Stmt is complete (ends with ; or {) and not in a quote
      If (NOT InQuote) and
         (NOT bLineCmt) and
         (NOT inComment) and
         ( %Scan(';' : srcLine) > 0 Or %Scan('{' : srcLine) > 0 );
         StmtComplete = *On;

      EndIf;
   EndDo;

    srcStmt = srcLine;
    Comments = srcCmt;
    Return src_EOF;

    end-Proc;
