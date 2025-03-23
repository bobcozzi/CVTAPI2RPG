
      /IF NOT DEFINED(RPGTYPEDEF_SRCRCD_T)
      /DEFINE RPGTYPEDEF_SRCRCD_T
            // Standard IBM i Source File record layout
            // uses the Max SEU supported source file lenght (240)
            // runtime size can be gotten from the source files' INFDS
           dcl-ds SRCRCD_T Qualified Inz TEMPLATE;
               srcseq  Zoned(6 : 2);
               srcdate Zoned(6 : 0);
               srcData char(MAX_SRCLINE_LEN);
           end-ds;
      /ENDIF
