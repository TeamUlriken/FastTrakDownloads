ALTER PROCEDURE dbo.UpdateFormText ( @EventId INT, @FormId INT, @CachedText VARCHAR(MAX) ) AS
BEGIN
  UPDATE dbo.ClinForm SET CachedText=@CachedText 
  WHERE ( FormId=@FormId ) AND ( EventId=@EventId ) AND ( ISNULL(CachedText,'') <> ISNULL(@CachedText,'') );
END
GO

DROP TRIGGER dbo.T_ClinForm_Update
GO

CREATE TRIGGER dbo.T_ClinForm_Update ON dbo.ClinForm
AFTER UPDATE AS 
BEGIN   
   IF UPDATE(Comment) OR UPDATE (SignedAt) OR UPDATE(DeletedAt)                 
     INSERT INTO dbo.ClinFormLog( ClinFormId, Comment, FormStatus, FormComplete, SignedAt, SignedBy )
     SELECT o.ClinFormId, o.Comment, o.FormStatus, o.FormComplete, o.SignedAt, o.SignedBy 
     FROM deleted o;
END
GO