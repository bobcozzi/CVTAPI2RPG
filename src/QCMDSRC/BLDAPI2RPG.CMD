 BLDAPI2RPG: CMD        PROMPT('Compile the CVTAPI2RPG command')
             PARM       KWD(SRCLIB) TYPE(*NAME) LEN(10) DFT(*CURLIB) +
                          SPCVAL((*CURLIB *CURLIB) (RPGFREE) +
                          (RPGHELPER)) EXPR(*YES) PROMPT('Source +
                          Library')
             PARM       KWD(OBJLIB) TYPE(*NAME) LEN(10) DFT(*SRCLIB) +
                          SPCVAL((*CURLIB *CURLIB) (*SRCLIB)) +
                          EXPR(*YES) PROMPT('Object Library')
