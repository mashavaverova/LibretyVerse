import { Schema, model } from 'mongoose';

const AdminLogSchema = new Schema({
    adminAddress: { type: String, required: true }, // Address of the admin
    action: { type: String, required: true }, // Action performed, e.g., "grantRole", "revokeRole"
    role: { type: String }, // Role affected, e.g., "PLATFORM_ADMIN_ROLE"
    targetAddress: { type: String }, // Address affected by the action
    timestamp: { type: Date, default: Date.now }, // When the action occurred
    status: { type: String, default: 'success' }, // Status of the action, e.g., "success" or "failed"
    error: { type: String } // Any error encountered during the action
});

export default model('AdminLog', AdminLogSchema);
