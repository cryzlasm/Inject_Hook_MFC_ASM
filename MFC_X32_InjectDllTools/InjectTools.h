// InjectTools.h : main header file for the INJECTTOOLS application
//

#if !defined(AFX_INJECTTOOLS_H__0E8C3BE9_2C19_4E76_8B77_DCA5199BFE90__INCLUDED_)
#define AFX_INJECTTOOLS_H__0E8C3BE9_2C19_4E76_8B77_DCA5199BFE90__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CInjectToolsApp:
// See InjectTools.cpp for the implementation of this class
//

class CInjectToolsApp : public CWinApp
{
public:
	CInjectToolsApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CInjectToolsApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CInjectToolsApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_INJECTTOOLS_H__0E8C3BE9_2C19_4E76_8B77_DCA5199BFE90__INCLUDED_)
