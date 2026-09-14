/**
 * A client–advocate relationship, created the moment the advocate accepts a
 * consultation request. Cases can only be opened for clients the advocate
 * already has a relationship with.
 */
export interface ClientRelationship {
  id: string;
  advocateId: string;
  clientId: string;
  /** The consultation whose acceptance created the relationship. */
  bookingId: string;
  createdAt: string;
}
