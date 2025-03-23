
      /IF NOT DEFINED(RPGTYPEDEF_INFDS)
      /DEFINE RPGTYPEDEF_INFDS

           DCL-C  INFDS_FILENAME_POS  83;
           DCL-C  INFDS_LIBNAME_POS   93;
           DCL-C  INFDS_MBRNAME_POS  129;
           DCL-C  INFDS_RCDLEN_POS   125;
           DCL-C  INFDS_KEYLEN_POS   127;
           DCL-C  INFDS_RCDCOUNT_POS 156;

           DCL-DS SRCINFDS_T Qualified;
                   rt_FileName char(10) POS(83);    // Runtime file name
                   rt_Library  char(10) POS(93);    // Runtime library name
                   rt_Mbr      char(10) POS(129);   // Runtime member name
                   rcdLen      int(5)   POS(125);   // Record length
                   keyLen      int(5)   POS(127);   // Key length (or 0 if not keyed)
                   rcdCount    int(10)  POS(156);   // Number of records in file/member
            end-DS;

      /ENDIF