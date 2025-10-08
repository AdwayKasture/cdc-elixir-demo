CREATE TABLE IF NOT EXISTS public.products_wal (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- audit log table
CREATE TABLE IF NOT EXISTS public.products_wal_log (
    log_id BIGSERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    operation_type CHAR(1) NOT NULL, -- I/U/D (Insert, Update, Delete)
    changed_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    old_data JSONB,
    new_data JSONB
);

CREATE OR REPLACE FUNCTION public.log_product_changes()
RETURNS TRIGGER AS $$
DECLARE
    operation_label TEXT;
    notification_payload TEXT;
    old_data_json JSONB;
    new_data_json JSONB;
BEGIN
    -- Determine operation type
    operation_label := SUBSTRING(TG_OP, 1, 1); -- 'I', 'U', or 'D'
    
    -- === 1. CAPTURE DATA AND LOG CHANGE ===
    
    -- Default to NULL
    old_data_json := NULL;
    new_data_json := NULL;

    IF TG_OP = 'INSERT' THEN
        new_data_json := to_jsonb(NEW);
        
        INSERT INTO public.products_wal_log (product_id, operation_type, new_data)
        VALUES (NEW.id, operation_label, new_data_json);

    ELSIF TG_OP = 'UPDATE' THEN
        old_data_json := to_jsonb(OLD);
        new_data_json := to_jsonb(NEW);

        INSERT INTO public.products_wal_log (product_id, operation_type, new_data, old_data)
        VALUES (NEW.id, operation_label, new_data_json, old_data_json);
        
    ELSIF TG_OP = 'DELETE' THEN
        old_data_json := to_jsonb(OLD);

        INSERT INTO public.products_wal_log (product_id, operation_type, old_data)
        VALUES (OLD.id, operation_label, old_data_json);
    END IF;

    -- === 2. SEND NOTIFY (Structured Payload) ===
    
    -- Build the structured JSON payload: {action: 'I/U/D', old: {...}, new: {...}}
    notification_payload := json_build_object(
        'action', operation_label,
        'table', TG_TABLE_NAME,
        'old', old_data_json,
        'new', new_data_json
    )::text;

    PERFORM pg_notify(
        'product_cdc_channel',
        notification_payload
    );

    -- Return the appropriate row for AFTER triggers
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- Apply the trigger to fire AFTER any INSERT, UPDATE, or DELETE
CREATE TRIGGER products_wal_cdc_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.products_wal
FOR EACH ROW
EXECUTE FUNCTION public.log_product_changes();
