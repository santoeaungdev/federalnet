SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

ALTER TABLE owner_wallet_transactions
    ADD COLUMN idempotency_key VARCHAR(128) NULL;

CREATE INDEX idx_owner_idempotency ON owner_wallet_transactions (owner_id, idempotency_key);

COMMIT;
