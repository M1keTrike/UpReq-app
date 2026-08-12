/// Identificadores de entidad, cada uno un extension type distinto sobre `String`
/// para que el analizador impida mezclarlos entre sí (p. ej. pasar un
/// `StakeholderId` donde se espera un `ProjectId`).
extension type const ProjectId(String value) {}

extension type const StakeholderId(String value) {}

extension type const SessionId(String value) {}

extension type const ScriptPointId(String value) {}

extension type const GlossaryTermId(String value) {}

extension type const AuditEntryId(String value) {}

extension type const RecordingId(String value) {}

extension type const LiveMarkId(String value) {}

extension type const TranscriptId(String value) {}

extension type const SegmentId(String value) {}
