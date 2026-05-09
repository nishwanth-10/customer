-- Customer Ledger Pro — PostgreSQL Initial Schema
-- Run this manually or let SQLAlchemy/Alembic auto-create

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Enums ─────────────────────────────────────────────────────────────────────
CREATE TYPE userrole AS ENUM ('super_admin', 'business_owner', 'staff');
CREATE TYPE authprovider AS ENUM ('email', 'google', 'phone');
CREATE TYPE paymentstatus AS ENUM ('paid', 'pending', 'overdue', 'partial');
CREATE TYPE transactiontype AS ENUM ('credit', 'debit');
CREATE TYPE billstatus AS ENUM ('unpaid', 'paid', 'partial', 'waived');
CREATE TYPE paymentmethod AS ENUM ('cash', 'upi', 'bank_transfer', 'cheque', 'card', 'other');
CREATE TYPE notificationtype AS ENUM ('sms', 'whatsapp', 'push', 'email');
CREATE TYPE notificationstatus AS ENUM ('pending', 'sent', 'failed', 'delivered');
CREATE TYPE subscriptionplan AS ENUM ('free', 'basic', 'professional', 'enterprise');
CREATE TYPE subscriptionstatus AS ENUM ('active', 'expired', 'cancelled', 'trial');

-- ── Users ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    hashed_password VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    role userrole NOT NULL DEFAULT 'business_owner',
    auth_provider authprovider NOT NULL DEFAULT 'email',
    google_id VARCHAR(255) UNIQUE,
    firebase_uid VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    otp_code VARCHAR(10),
    otp_expires_at TIMESTAMPTZ,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- ── Businesses ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    gst_number VARCHAR(20),
    currency VARCHAR(3) DEFAULT 'INR',
    currency_symbol VARCHAR(5) DEFAULT '₹',
    timezone_str VARCHAR(50) DEFAULT 'Asia/Kolkata',
    reminder_day INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    is_suspended BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Customers ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    whatsapp_number VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    avatar_url TEXT,
    notes TEXT,
    monthly_payment_amount NUMERIC(12, 2) DEFAULT 0.00,
    due_amount NUMERIC(12, 2) DEFAULT 0.00,
    total_paid NUMERIC(12, 2) DEFAULT 0.00,
    opening_balance NUMERIC(12, 2) DEFAULT 0.00,
    payment_status paymentstatus DEFAULT 'pending',
    last_payment_date DATE,
    due_date DATE,
    reminder_enabled BOOLEAN DEFAULT TRUE,
    whatsapp_reminder BOOLEAN DEFAULT TRUE,
    sms_reminder BOOLEAN DEFAULT TRUE,
    push_reminder BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Transactions ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    transaction_type transactiontype NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    description TEXT,
    reference_number VARCHAR(100),
    transaction_date DATE NOT NULL,
    balance_after NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Monthly Bills ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS monthly_bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    bill_month INTEGER NOT NULL,
    bill_year INTEGER NOT NULL,
    due_date DATE NOT NULL,
    amount_due NUMERIC(12, 2) NOT NULL,
    amount_paid NUMERIC(12, 2) DEFAULT 0.00,
    amount_remaining NUMERIC(12, 2) DEFAULT 0.00,
    status billstatus DEFAULT 'unpaid',
    paid_on DATE,
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, bill_month, bill_year)
);

-- ── Payments ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    monthly_bill_id UUID REFERENCES monthly_bills(id),
    collected_by UUID NOT NULL REFERENCES users(id),
    amount NUMERIC(12, 2) NOT NULL,
    payment_method paymentmethod DEFAULT 'cash',
    payment_date DATE NOT NULL,
    reference_number VARCHAR(100),
    notes TEXT,
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Notifications ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id),
    notification_type notificationtype NOT NULL,
    status notificationstatus DEFAULT 'pending',
    recipient_number VARCHAR(20),
    recipient_email VARCHAR(255),
    fcm_token TEXT,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    provider_message_id VARCHAR(255),
    error_message TEXT,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Audit Logs ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    business_id UUID REFERENCES businesses(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255),
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Subscriptions ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    plan subscriptionplan DEFAULT 'free',
    status subscriptionstatus DEFAULT 'trial',
    start_date DATE NOT NULL,
    end_date DATE,
    amount_paid NUMERIC(10, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'INR',
    payment_reference VARCHAR(255),
    max_customers INTEGER DEFAULT 10,
    auto_renew BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX idx_customers_business ON customers(business_id);
CREATE INDEX idx_customers_status ON customers(payment_status);
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_transactions_business ON transactions(business_id);
CREATE INDEX idx_transactions_customer ON transactions(customer_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_notifications_business ON notifications(business_id);
CREATE INDEX idx_audit_business ON audit_logs(business_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
