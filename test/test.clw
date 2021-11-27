  PROGRAM

  INCLUDE('datagrid.inc'), ONCE

  MAP
    INCLUDE('printf.inc'), ONCE
  END


DataQ                         QUEUE, PRE(DataQ)
ExpDate                         LONG
ExpDate_Style                   LONG
Value1                          LONG
Value1_Style                    LONG
Value2                          LONG
Value2_Style                    LONG
Value3                          LONG
Value3_Style                    LONG
Value4                          LONG
Value4_Style                    LONG
                              END

i                             LONG, AUTO

Window                        WINDOW('DataGrid example'),AT(,,309,171),CENTER,GRAY,SYSTEM,FONT('Segoe UI',9)
                                LIST,AT(11,14,288,116),USE(?lstData),HVSCROLL,COLUMN,FROM(DataQ), |
                                  FORMAT('53L(2)|MY~Data~@d10-@60R(2)|MY~Value1~@n-10@60R(2)|MY~Value2~@n-' & |
                                  '10@60R(2)|MY~Value3~@n-10@60R(2)|MY~Value4~@n-10@')
                                BUTTON('Export to CSV'),AT(175,146,63),USE(?btnExport)
                                BUTTON('Exit'),AT(257,146,42),USE(?btnExit),STD(STD:Close)
                              END

dg                            CLASS(TDataGrid)
ToCsv                           PROCEDURE(STRING pCsvFile)
                              END


  CODE
  LOOP i=1 TO 100
    CLEAR(DataQ)
    DataQ.ExpDate = TODAY()-(i-1)
    DataQ.Value1 = RANDOM(0, 100)
    DataQ.Value2 = RANDOM(0, 100)
    DataQ.Value3 = RANDOM(0, 100)
    DataQ.Value4 = RANDOM(0, 100)
    ADD(DataQ)
  END
  SORT(DataQ, DataQ.ExpDate)
  
  OPEN(Window)
  
  !- define selection style
  ?lstData{PROPSTYLE:BackColor, 1} = COLOR:Yellow
  
  dg.Init(?lstData)
  dg.SetDataSource(DataQ)
  dg.SelectedStyle(1) !- set style #1 as selected style
  
  ACCEPT
    CASE ACCEPTED()
    OF ?btnExport
      dg.ToCsv('test.csv')
    END
  END

  
dg.ToCsv                      PROCEDURE(STRING pCsvFile)
nrow                            LONG, AUTO
ncol                            LONG, AUTO
df                              TDiskFile
sHeader                         STRING(256), AUTO
sValue                          STRING(20), AUTO
  CODE
  IF SELF.selectedRect.top = 0
    !- no selection yet
    MESSAGE('Select a range of cells first!', 'Error', ICON:Exclamation)
    RETURN
  END
  
  IF df.CreateFile(pCsvFile, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0)    

    !- write columns header
    sHeader = 'Date,Value 1,Value 2,Value 3,Value 4<13,10>'
    df.WriteMem(ADDRESS(sHeader), LEN(CLIP(sHeader)))

    !- for each selected row
    LOOP nrow=SELF.selectedRect.top TO SELF.selectedRect.bottom
      GET(DataQ, nrow)
    
      !- for each selected column
      LOOP ncol=SELF.selectedRect.left TO SELF.selectedRect.right
        
        !- read cell value
        EXECUTE ncol
          sValue = FORMAT(DataQ.ExpDate, @d17)
          sValue = DataQ.Value1
          sValue = DataQ.Value2
          sValue = DataQ.Value3
          sValue = DataQ.Value4
        END
        
        !- write cell value to the file
        df.WriteMem(ADDRESS(sValue), LEN(CLIP(sValue)))
        
        IF ncol < SELF.selectedRect.right
          !- separate by comma
          sValue = ','
          df.WriteMem(ADDRESS(sValue), LEN(CLIP(sValue)))
        ELSE
          !- start next line
          sValue = '<13,10>'
          df.WriteMem(ADDRESS(sValue), LEN(CLIP(sValue)))
        END
      END
    END

    df.CloseHandle()
    
    MESSAGE(printf('File %s was created successfully.', pCsvFile), 'Success', ICON:Asterisk)
  ELSE
    MESSAGE(printf('Unable to create file %s.', pCsvFile), 'Error', ICON:Exclamation)
  END
  