!- DataGrid ckasses.
!- mikeduglas@yandex.ru 2021

  INCLUDE('winapi.inc'), ONCE




TDataGridBase                 CLASS(TWnd), TYPE, MODULE('datagrid.clw'), LINK('datagrid.clw')
qDataSource                     &QUEUE, PROTECTED
aStyleColumns                   LONG, DIM(255), PROTECTED       !- style columns numbers
nCurRow                         UNSIGNED, PROTECTED             !- current cell's row
nCurCol                         UNSIGNED, PROTECTED             !- current cell's column
bIsSelecting                    BOOL, PROTECTED

Init                            PROCEDURE(SIGNED pFeq), DERIVED
SetDataSource                   PROCEDURE(QUEUE pQ)
Activate                        PROCEDURE(BOOL pVal), VIRTUAL
IsActive                        PROCEDURE(), BOOL               !- true: grid mode is active

OnCellSelectionStarted          PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey), VIRTUAL, PROTECTED
OnCellSelectionChanged          PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey), VIRTUAL, PROTECTED
OnCellSelectionStopped          PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey), VIRTUAL, PROTECTED

OnLButtonDown                   PROCEDURE(UNSIGNED wParam, LONG lParam), VIRTUAL, PROTECTED, BOOL, PROC
OnLButtonUp                     PROCEDURE(UNSIGNED wParam, LONG lParam), VIRTUAL, PROTECTED, BOOL, PROC
OnMouseMove                     PROCEDURE(UNSIGNED wParam, LONG lParam), VIRTUAL, PROTECTED, BOOL, PROC
                              END


TDataGrid                     CLASS(TDataGridBase), TYPE, MODULE('datagrid.clw'), LINK('datagrid.clw')
startCell                       LIKE(POINT), PROTECTED
selectedCell                    LIKE(POINT), PROTECTED
selectedRect                    &TRect, PROTECTED
nSelectedStyle                  LONG, PROTECTED

Construct                       PROCEDURE()
Destruct                        PROCEDURE(), DERIVED

SelectedStyle                   PROCEDURE(<LONG pStyle>), LONG, PROC

ResetSelection                  PROCEDURE(), VIRTUAL
ModifySelection                 PROCEDURE(), PRIVATE
ApplyStyle                      PROCEDURE(LONG pStyle), VIRTUAL, PROTECTED

OnCellSelectionStarted          PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey), DERIVED, PROTECTED
OnCellSelectionChanged          PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey), DERIVED, PROTECTED
OnCellSelectionStopped          PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey), DERIVED, PROTECTED

OnLButtonDown                   PROCEDURE(UNSIGNED wParam, LONG lParam), DERIVED, PROTECTED, BOOL, PROC
OnLButtonUp                     PROCEDURE(UNSIGNED wParam, LONG lParam), VIRTUAL, PROTECTED, BOOL, PROC
OnMouseMove                     PROCEDURE(UNSIGNED wParam, LONG lParam), VIRTUAL, PROTECTED, BOOL, PROC
                              END

