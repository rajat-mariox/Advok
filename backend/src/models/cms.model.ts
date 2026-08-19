export interface CmsSection {
  title: string;
  body: string;
}

/** Admin-editable app page (Terms & Conditions, Privacy Policy, ...). */
export interface CmsPage {
  slug: string;
  title: string;
  sections: CmsSection[];
  /** Label shown at the bottom of the page in the app, e.g. "Last updated: January 1, 2025". */
  lastUpdatedLabel: string;
  updatedAt: string;
}
