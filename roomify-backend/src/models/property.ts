import { Model } from 'sutando';
import { User} from './user'

export class Property extends Model {
    id!: number;
    userId!: string;  // Ensure this matches the type of User.id if not using strings
    title!: string;
    description!: string;
    createdAt!: Date;
    location!: string;
    numberOfRooms!: number;
    price!: number;
    isFavourite!: boolean;
    imageUrls!: string[];  // Assuming images are stored as an array of URLs
    propertyTags!: string[];  // Assuming tags are stored as an array of strings
    updated_at!: Date;

    casts = {
        isFavourite: 'boolean'
    }

    relationUser() {
        return this.belongsTo(User, 'userId');
    }

    relationComments() {
        return this.hasMany(Comment, 'propertyId');
    }
}

export class Comment extends Model {
    id!: number;
    userId!: string;  // Reference to the user who made the comment
    propertyId!: number;  // Reference to the property the comment is about, if applicable
    comment!: string;
    created_at!: Date;
    updated_at!: Date;

    // Relationship to User
    relationUser() {
        return this.belongsTo(User, 'userId');
    }

    // Optional: Relationship to Property if comments are property-specific
    relationProperty() {
        return this.belongsTo(Property, 'propertyId');
    }
}

