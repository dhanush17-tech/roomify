import { Model } from 'sutando';
import { Property } from './property';
import { Item } from './item';

export class User extends Model {
    id!: string;  // Using string assuming UUIDs, change to number if using numerical IDs
    username!: string;
    displayName!: string;
    profileImageUrl!: string;
    bio!: string;
    email!: string;
    language!: string;
    receiveNotifications!: boolean;
    created_at!: Date;
    updated_at!: Date;

    relationProperties() {
        return this.hasMany(Property, 'userId');
    }

    relationItems() {
        return this.hasMany(Item, 'userId');
    }
}
