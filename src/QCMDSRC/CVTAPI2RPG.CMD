 CVTAPI2RPG: CMD        PROMPT('Convert C typedef->RPG DCL-DS')

             PARM       KWD(FROMFILE) TYPE(QSRC1) PROMPT('C source +
                          header file')
 QSRC1:      QUAL       TYPE(*NAME) LEN(10) DFT(H) EXPR(*YES)
             QUAL       TYPE(*NAME) LEN(10) DFT(QSYSINC) +
                          SPCVAL((QSYSINC) (*LIBL) (*CURLIB)) +
                          EXPR(*YES) PROMPT('C Source file library')
             PARM       KWD(FROMMBR) TYPE(*NAME) LEN(10) EXPR(*YES) +
                          PROMPT('C Input Source member')
             PARM       KWD(TOFILE) TYPE(QSRC2) PROMPT('RPG Source file')
 QSRC2:      QUAL       TYPE(*NAME) LEN(10) DFT(QCPYSRC) +
                          SPCVAL((QCPYSRC) (QRPGLESRC)) EXPR(*YES)
             QUAL       TYPE(*NAME) LEN(10) DFT(*CURLIB) +
                          SPCVAL((*CURLIB *CURLIB)) EXPR(*YES) +
                          PROMPT('RPG IV Source file library')
             PARM       KWD(TOMBR) TYPE(*NAME) LEN(10) +
                          DFT(*FROMMBR) SPCVAL((*FROMMBR)) +
                          EXPR(*YES) PROMPT('RPG IV Output source member')
             PARM       KWD(CRTMBR) TYPE(*INT2) RSTD(*YES) DFT(*NO) +
                          SPCVAL((*YES 1) (*NO 0)) EXPR(*YES) +
                          PROMPT('Create TOMBR if necessary')
             PARM       KWD(DTAOPT) TYPE(*INT2) RSTD(*YES) +
                          DFT(*APPEND) SPCVAL((*ADD 1) (*REPLACE 2) +
                          (*APPEND 1) (*OVERWRITE 2) (*CLEAR 2)) +
                          PROMPT('TOMBR data option')
             PARM       KWD(TYPEDEF) TYPE(*PNAME) LEN(128) DFT(*ALL) +
                          SPCVAL((*ALL)) EXPR(*YES) VARY(*YES) +
                          PROMPT('Typedef name')
