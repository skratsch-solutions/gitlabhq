import { marked } from 'marked';
import markedBidi from 'marked-bidi';
import { sanitize } from '~/lib/dompurify';
import { markdownConfig } from '~/lib/utils/text_utility';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { sprintf } from '~/locale';
import { UPDATE_COMMENT_FORM, COMMENT_FORM } from './i18n';

/**
 * Tracks snowplow event when User toggles timeline view
 * @param {Boolean} enabled that will be send as a property for the event
 */
export const trackToggleTimelineView = (enabled) => ({
  category: 'Incident Management', // eslint-disable-line @gitlab/require-i18n-strings
  action: 'toggle_incident_comments_into_timeline_view',
  label: 'Status', // eslint-disable-line @gitlab/require-i18n-strings
  property: enabled,
});

marked.use(markedBidi());

export const renderMarkdown = (rawMarkdown) => {
  return sanitize(marked(rawMarkdown), markdownConfig);
};

export const getNoteFormErrorMessages = (response, messages) => {
  const { error: errorMessage, defaultError: defaultErrorMessage } = messages || COMMENT_FORM;
  if (response && response.status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
    if (response.data?.quick_actions_status?.error_messages?.length) {
      return response.data?.quick_actions_status.error_messages;
    }

    const errors = response.data?.errors;
    if (errorMessage && errors) {
      return [sprintf(errorMessage, { reason: errors.toLowerCase() }, false)];
    }
  }

  return [defaultErrorMessage || COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK];
};

export const updateNoteErrorMessage = (e) => {
  const errors = e?.response?.data?.errors;

  if (errors) {
    return sprintf(UPDATE_COMMENT_FORM.error, { reason: errors.toLowerCase() }, false);
  }

  return UPDATE_COMMENT_FORM.defaultError;
};

/**
 * Whether a system note should render with the styled GitLab Duo treatment
 * (avatar + progress spinner) rather than as a plain system note.
 *
 * Two distinct notes qualify:
 * - Duo mention notes (action `duo_mention_started`): identified by the presence
 *   of `duo_session_status`, which EE::NoteEntity serializes only for them. This
 *   covers both the @GitLabDuo bot and the @duo-developer service account.
 * - The Duo Code Review progress note (action `duo_code_review_started`): it has
 *   no `duo_session_status`, so it is matched via its bot author's user_type.
 *   `duo_code_review_bot` is the dedicated internal GitLab Duo user (see
 *   Users::Internal); it is the author's account type, not a per-note flag.
 */
export const shouldRenderAsDuoSystemNote = (note) =>
  Boolean(note?.system) &&
  (note.duo_session_status !== undefined || note.author?.user_type === 'duo_code_review_bot');

/**
 * Finds the Duo "thinking" note that an incoming reply should remove.
 *
 * Duo posts the thinking note and its reply as the same author (the Duo bot or
 * the mention service account) in the same discussion, so removal is keyed off
 * that author match: a human comment landing in the discussion while Duo is
 * still working has a different author and must not remove the note early.
 *
 * Callers must pass the full discussions list, not a filtered subset, so the
 * reply's discussion (which always holds the thinking note) is in scope.
 *
 * @param {Array} incomingNotes - Notes received from the poll endpoint.
 * @param {Array} discussions   - Current discussions to search within.
 * @returns {Object|null} The started note to remove, or null if none found.
 */
export const findStartedNoteForReply = (incomingNotes, discussions) => {
  for (const note of incomingNotes) {
    if (note.system) continue;

    const discussion = discussions.find((d) => d.id === note.discussion_id);
    if (!discussion) continue;

    const startedNote = discussion.notes?.find((n) => shouldRenderAsDuoSystemNote(n));
    if (!startedNote) continue;

    if (note.author?.id != null && note.author.id === startedNote.author?.id) {
      return startedNote;
    }
  }

  return null;
};

export const isSlashCommand = (message) => {
  const trimmedMessage = message
    ?.split('\n')
    .filter((line) => line.trim() !== '')
    .join('\n');
  return trimmedMessage?.startsWith('/') || false;
};
