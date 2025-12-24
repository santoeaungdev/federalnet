SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

-- Extend tbl_users.user_type enum to include Owner and Operator
ALTER TABLE tbl_users
    MODIFY COLUMN user_type ENUM('SuperAdmin','Admin','Report','Agent','Sales','Owner','Operator') NOT NULL;

COMMIT;
