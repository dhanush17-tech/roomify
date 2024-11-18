import {User} from './user'
import { Model } from 'sutando';

export class Item extends Model {
    id!: number;
    userId!: string;  // Reference to the user who listed the item
    title!: string;
    description!: string;
    createdAt!: Date;
    location!: string;
    price!: number;
    isFavourite!: boolean;  // Tracks whether the item is marked as a favorite by users
    imageUrls!: string[];  // Assuming items may have multiple images
    updated_at!: Date;

    casts = {
        isFavourite: 'boolean'  // Ensures the isFavourite field is treated as a boolean
    }

    // Relationship to User
    relationUser() {
        return this.belongsTo(User, 'userId');
    }
}