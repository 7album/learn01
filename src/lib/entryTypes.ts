export type EntryType = 'milestone' | 'learning_note';

export type EntryRecord = {
	id: string;
	type: EntryType;
	title: string;
	description?: string | null;
	category?: string | null;
	content?: string | null;
	tags?: string[] | null;
	event_date?: string | null;
	created_at?: string | null;
	updated_at?: string | null;
};