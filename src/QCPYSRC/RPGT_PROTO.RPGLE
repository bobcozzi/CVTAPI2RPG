
      /IF NOT DEFINED(RPGTYPEDEF_PROTO)
      /DEFINE RPGTYPEDEF_PROTO

      /IF NOT DEFINED(RPGTYPEDEF_INFDS)
        /include rpgfree/qcpysrc,rpgt_INFDS
      /ENDIF
                 dcl-pr readCStmt ind EXTPROC('readCStmt');
                      inSrcFile  LIKEFILE(QSRCFIN_T);
                      srcRcdLen  int(10) Const;
                      FullStmt   varCHAR(MAX_WORKSRC_LEN);
                      comment    varCHAR(MAX_WORKSRC_LEN);
                 end-pr;

      /ENDIF