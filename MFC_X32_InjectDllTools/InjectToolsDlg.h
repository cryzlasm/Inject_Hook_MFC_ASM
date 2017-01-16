// InjectToolsDlg.h : header file
//

#if !defined(AFX_INJECTTOOLSDLG_H__FF85E641_66D5_4CEE_B3D5_5703817AA508__INCLUDED_)
#define AFX_INJECTTOOLSDLG_H__FF85E641_66D5_4CEE_B3D5_5703817AA508__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

/////////////////////////////////////////////////////////////////////////////
// CInjectToolsDlg dialog

class CInjectToolsDlg : public CDialog
{
// Construction
public:
	CInjectToolsDlg(CWnd* pParent = NULL);	// standard constructor

    //判断是否已经获取到DLL路径
    BOOL m_bIsGetPath;
    
    BOOL FindDlgAndGetPID(DWORD& dwOutPid);
    BOOL OpenProcessAndAllocBuf(DWORD dwPid, HANDLE& hOutProcess, LPVOID& pOutBuf);
    BOOL WriteDataAndStartThread(HANDLE& hOutThread, HANDLE& hProcess, LPVOID& lpBuf);
// Dialog Data
	//{{AFX_DATA(CInjectToolsDlg)
	enum { IDD = IDD_INJECTTOOLS_DIALOG };
	CButton	m_InjectCtl;
	CButton	m_BtnGetDllPathCtl;
	CEdit	m_DllPathCtl;
	CString	m_strDllPath;
	CString	m_strDstName;
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CInjectToolsDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	//{{AFX_MSG(CInjectToolsDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	virtual void OnOK();
	afx_msg void OnBtnGetdllpath();
	afx_msg void OnBtnInject();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_INJECTTOOLSDLG_H__FF85E641_66D5_4CEE_B3D5_5703817AA508__INCLUDED_)
