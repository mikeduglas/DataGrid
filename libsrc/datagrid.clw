!- DataGrid classes.
!- mikeduglas@yandex.ru 2021

  MEMBER

  INCLUDE('datagrid.inc'), ONCE

  MAP
    lb::SubclassProc(HWND hWnd, ULONG wMsg, UNSIGNED wParam, LONG lParam, ULONG subclassId, UNSIGNED dwRefData), LONG, PASCAL, PRIVATE
    LOWORD(LONG pLongVal), LONG, PRIVATE
    HIWORD(LONG pLongVal), LONG, PRIVATE

    INCLUDE('printf.inc'), ONCE
  END

eq::StyleFieldNameSuffix      EQUATE('_STYLE')  !- style field name ends with "_Style"


!!!region callbacks
lb::SubclassProc              PROCEDURE(HWND hWnd, ULONG wMsg, UNSIGNED wParam, LONG lParam, ULONG subclassId, UNSIGNED dwRefData)
win                             TWnd
ctrl                            &TDataGridBase
  CODE
  win.SetHandle(hWnd)
  !- get TDataGridBase instance
  ctrl &= (dwRefData)
  IF ctrl &= NULL
    !- not our window
    RETURN win.DefSubclassProc(wMsg, wParam, lParam)
  END
  
  CASE wMsg
  OF WM_LBUTTONDOWN
    !- let Clarion make its job
    ctrl.DefSubclassProc(wMsg, wParam, lParam)
    !- then process the message
    ctrl.OnLButtonDown(wParam, lParam)
    RETURN 0

  OF WM_LBUTTONUP
    !- let Clarion make its job
    ctrl.DefSubclassProc(wMsg, wParam, lParam)
    !- then process the message
    ctrl.OnLButtonUp(wParam, lParam)
    RETURN 0

  OF WM_MOUSEMOVE
    !- let Clarion make its job
    ctrl.DefSubclassProc(wMsg, wParam, lParam)
    !- then process the message
    ctrl.OnMouseMove(wParam, lParam)
    RETURN 0
    
  END

  !- call original window proc
  RETURN ctrl.DefSubclassProc(wMsg, wParam, lParam)
!!!endregion
  
!!!region static functions
LOWORD                        PROCEDURE(LONG pLongVal)
  CODE
  RETURN BAND(pLongVal, 0FFFFh)

HIWORD                        PROCEDURE(LONG pLongVal)
  CODE
  RETURN BSHIFT(BAND(pLongVal, 0FFFF0000h), -16)
!!!endregion
  
!!!region TDataGridBase
TDataGridBase.Init            PROCEDURE(SIGNED pFeq)
  CODE
  ASSERT(pFeq{PROP:Type} = CREATE:list)
  IF pFeq{PROP:Type} = CREATE:list
    PARENT.Init(pFeq)
    !- subclass the list.
    SELF.SetWindowSubclass(ADDRESS(lb::SubclassProc), 0, ADDRESS(SELF))
  ELSE
    printd('TDataGridBase.Init(%i): unsupported control type.', pFeq)
  END

TDataGridBase.SetDataSource   PROCEDURE(QUEUE pQ)
refQ                            ANY
refFld                          ANY
fldName                         STRING(255), AUTO
i                               LONG, AUTO
j                               LONG, AUTO
  CODE
  SELF.qDataSource &= pQ
  CLEAR(SELF.aStyleColumns)
  
  j = 1
  LOOP i=1 TO 9999
    refQ &= WHAT(pQ, i)
    IF refQ &= NULL
      BREAK
    END
    
    fldName = UPPER(WHO(pQ, i))
    IF SUB(fldName, LEN(CLIP(fldName))-SIZE(eq::StyleFieldNameSuffix)+1, SIZE(eq::StyleFieldNameSuffix)) = eq::StyleFieldNameSuffix
      SELF.aStyleColumns[j] = i
      j += 1
    END
  END
  
  
TDataGridBase.Activate        PROCEDURE(BOOL pVal)
  CODE
  IF pVal AND NOT SELF.IsActive()
    !- set PROP:Column to 1 if it is 0, otherwise don't change PROP:Column.
    SELF.FEQ{PROP:Column} = 1
  ELSE
    SELF.FEQ{PROP:Column} = 0
  END
  
TDataGridBase.IsActive        PROCEDURE()
  CODE
  RETURN CHOOSE(SELF.FEQ{PROP:Column} <> 0 AND NOT SELF.qDataSource &= NULL)

TDataGridBase.OnCellSelectionStarted  PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey)
  CODE
  
TDataGridBase.OnCellSelectionChanged  PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey)
  CODE

TDataGridBase.OnCellSelectionStopped  PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey)
  CODE

TDataGridBase.OnLButtonDown   PROCEDURE(UNSIGNED wParam, LONG lParam)
  CODE
  IF SELF.IsActive()
    SELF.bIsSelecting = TRUE
    SELF.nCurRow = SELF.FEQ{PROP:Selected}
    SELF.nCurCol = SELF.FEQ{PROP:Column}
    SELF.OnCellSelectionStarted(SELF.nCurRow, SELF.nCurCol, wParam)
    !- the message was processed
    RETURN TRUE
  END
  
  RETURN FALSE

TDataGridBase.OnLButtonUp     PROCEDURE(UNSIGNED wParam, LONG lParam)
  CODE
  IF SELF.IsActive() AND SELF.bIsSelecting
    SELF.bIsSelecting = FALSE
    SELF.OnCellSelectionStopped(SELF.nCurRow, SELF.nCurCol, wParam)
    !- the message was processed
    RETURN TRUE
  END
  
  RETURN FALSE

TDataGridBase.OnMouseMove     PROCEDURE(UNSIGNED wParam, LONG lParam)
  CODE
  IF SELF.IsActive() AND SELF.bIsSelecting
    IF SELF.nCurRow <> SELF.FEQ{PROP:Selected} OR SELF.nCurCol <> SELF.FEQ{PROP:Column}
      !- current cell was changed
      SELF.nCurRow = SELF.FEQ{PROP:Selected}
      SELF.nCurCol = SELF.FEQ{PROP:Column}
      SELF.OnCellSelectionChanged(SELF.nCurRow, SELF.nCurCol, wParam)
    END
    !- the message was processed
    RETURN TRUE
  END
  
  RETURN FALSE
!!!endregion
  
!!!region TDataGrid
TDataGrid.Construct           PROCEDURE()
  CODE
  SELF.selectedRect &= NEW TRect
  
TDataGrid.Destruct            PROCEDURE()
  CODE
  DISPOSE(SELF.selectedRect)
  
TDataGrid.SelectedStyle       PROCEDURE(<LONG pStyle>)
  CODE
  IF NOT OMITTED(pStyle)
    SELF.nSelectedStyle = pStyle
  END
  RETURN SELF.nSelectedStyle
  
TDataGrid.ResetSelection      PROCEDURE()
  CODE
  SELF.selectedRect.left = 0
  SELF.selectedRect.top = 0
  SELF.selectedRect.right = 0
  SELF.selectedRect.bottom = 0
  
TDataGrid.ModifySelection     PROCEDURE()
newSelection                    LIKE(_RECT_)
  CODE
  IF SELF.selectedCell.x >= SELF.startCell.x
    newSelection.left = SELF.startCell.x
    newSelection.right = SELF.selectedCell.x
  ELSE
    newSelection.left = SELF.selectedCell.x
    newSelection.right = SELF.startCell.x
  END
  IF SELF.selectedCell.y >= SELF.startCell.y
    newSelection.top = SELF.startCell.y
    newSelection.bottom = SELF.selectedCell.y
  ELSE
    newSelection.top = SELF.selectedCell.y
    newSelection.bottom = SELF.startCell.y
  END

  IF SELF.selectedRect.left <> 0
    !- we made a selection
    SELF.ApplyStyle(0)
  END
  
  SELF.selectedRect.Assign(newSelection)
  SELF.ApplyStyle(SELF.nSelectedStyle)

TDataGrid.ApplyStyle          PROCEDURE(LONG pStyle)
nrow                            UNSIGNED, AUTO
ncol                            UNSIGNED, AUTO
refFld                          ANY
  CODE
  ASSERT(NOT SELF.qDataSource &= NULL)
  IF SELF.qDataSource &= NULL
    RETURN
  END
  
  LOOP nrow=SELF.selectedRect.top TO SELF.selectedRect.bottom
    GET(SELF.qDataSource, nrow)

    LOOP ncol=SELF.selectedRect.left TO SELF.selectedRect.right
      refFld &= WHAT(SELF.qDataSource, SELF.aStyleColumns[ncol])
      IF NOT refFld &= NULL
        refFld = pStyle
      END
    END
    
    PUT(SELF.qDataSource)
  END
  DISPLAY(SELF.FEQ)
  
TDataGrid.OnCellSelectionStarted  PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey)
  CODE
  IF SELF.selectedRect.left <> 0
    SELF.ApplyStyle(0)
  END
  
  SELF.startCell.x = pColumn
  SELF.startCell.y = pRow
  
  SELF.selectedCell = SELF.startCell
  
  SELF.selectedRect.left = pColumn
  SELF.selectedRect.top = pRow
  SELF.selectedRect.right = pColumn
  SELF.selectedRect.bottom = pRow
  
  SELF.ApplyStyle(SELF.nSelectedStyle)
  
TDataGrid.OnCellSelectionChanged  PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey)
  CODE
  SELF.selectedCell.x = pColumn
  SELF.selectedCell.y = pRow
  
  SELF.ModifySelection()

TDataGrid.OnCellSelectionStopped  PROCEDURE(UNSIGNED pRow, UNSIGNED pColumn, UNSIGNED pVKey)
  CODE

TDataGrid.OnLButtonDown       PROCEDURE(UNSIGNED wParam, LONG lParam)
  CODE
  RETURN PARENT.OnLButtonDown(wParam, lParam)
  
TDataGrid.OnLButtonUp         PROCEDURE(UNSIGNED wParam, LONG lParam)
  CODE
  RETURN PARENT.OnLButtonUp(wParam, lParam)

TDataGrid.OnMouseMove         PROCEDURE(UNSIGNED wParam, LONG lParam)
  CODE
  RETURN PARENT.OnMouseMove(wParam, lParam)

!!!endregion
