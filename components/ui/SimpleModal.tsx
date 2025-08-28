import React from 'react';

interface SimpleModalProps {
    isOpen: boolean;
    title: string;
    onClose: () => void;
    children: React.ReactNode;
    footer?: React.ReactNode;
}

const overlayStyle: React.CSSProperties = {
    position: 'fixed',
    inset: 0,
    backgroundColor: 'rgba(0,0,0,0.35)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000
};

const modalStyle: React.CSSProperties = {
    backgroundColor: '#ffffff',
    borderRadius: 8,
    width: '90%',
    maxWidth: 480,
    boxShadow: '0 10px 25px rgba(0,0,0,0.15)'
};

const headerStyle: React.CSSProperties = {
    padding: '14px 16px',
    borderBottom: '1px solid #e5e7eb',
    fontWeight: 600,
    fontSize: 16
};

const bodyStyle: React.CSSProperties = {
    padding: 16
};

const footerStyle: React.CSSProperties = {
    padding: 16,
    borderTop: '1px solid #e5e7eb',
    display: 'flex',
    justifyContent: 'flex-end',
    gap: 8
};

export const SimpleModal: React.FC<SimpleModalProps> = ({ isOpen, title, onClose, children, footer }) => {
    if (!isOpen) return null;
    return (
        <div style={overlayStyle} onClick={onClose}>
            <div style={modalStyle} onClick={(e) => e.stopPropagation()}>
                <div style={headerStyle}>{title}</div>
                <div style={bodyStyle}>{children}</div>
                <div style={footerStyle}>
                    {footer}
                </div>
            </div>
        </div>
    );
};

export default SimpleModal;


