USE BlogX;

CREATE TABLE ApplicationUser(
	Id INT PRIMARY KEY IDENTITY(1, 1),
	UserName VARCHAR(50) NOT NULL,
	NormalizeUserName VARCHAR(50) NOT NULL,
	Email VARCHAR(50) NOT NULL,
	NormalizeEmail VARCHAR(50) NOT NULL,
	FullName VARCHAR(50) NULL,
	PasswordHash VARCHAR(MAX) NOT NULL
);

CREATE INDEX [IX_ApplicationUser_NormalizeUserName] ON [dbo].[ApplicationUser]([NormalizeUserName]);

CREATE INDEX [IX_ApplicationUser_NormalizeEmail] ON [dbo].[ApplicationUser] ([NormalizeEmail]);

CREATE TABLE Photo(
	Id INT IDENTITY(1, 1),
	ApplicationUserID INT NOT NULL,
	PublicId VARCHAR(50) NOT NULL,
	ImageUrl VARCHAR(MAX) NOT NULL,
	[Description] VARCHAR(50) NOT NULL,
	PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
	UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
	PRIMARY KEY(ID),
	FOREIGN KEY(ApplicationUserID) REFERENCES ApplicationUser(Id)
);

CREATE TABLE Blog(
	Id INT PRIMARY KEY IDENTITY(1, 1),
	ApplicationUserID INT NOT NULL,
	PhotoId INT NULL,
	Title VARCHAR(50) NOT NULL,
	Content VARCHAR(MAX) NOT NULL,
	PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
	UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
	IsActive BIT NOT NULL DEFAULT CONVERT(BIT, 1),
	FOREIGN KEY(ApplicationUserID) REFERENCES ApplicationUser(Id),
	FOREIGN KEY(PhotoId) REFERENCES Photo(Id)
);

CREATE TABLE BlogComment(
	Id INT PRIMARY KEY IDENTITY(1, 1),
	ParentCommentId INT NULL,
	BlogId INT NOT NULL,
	ApplicationUserID INT NOT NULL,
	Comment VARCHAR(500) NOT NULL,
	PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
	UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
	IsActive BIT NOT NULL DEFAULT CONVERT(BIT, 1),
	FOREIGN KEY(BlogId) REFERENCES Blog(Id),
	FOREIGN KEY(ApplicationUserID) REFERENCES ApplicationUser(Id)
);

CREATE SCHEMA [aggregate];

CREATE VIEW [aggregate].[Blog]
AS
	SELECT 
		Blog.Id,
		Blog.ApplicationUserID,
		AppUser.UserName,
		Blog.Title,
		Blog.Content,
		Blog.PhotoId,
		Blog.PublishDate,
		Blog.UpdateDate,
		Blog.IsActive
	FROM 
	dbo.Blog AS Blog 
	INNER JOIN 
	dbo.ApplicationUser AS AppUser 
	ON Blog.ApplicationUserID = AppUser.Id;


CREATE VIEW [aggregate].[BlogComment]
AS

	SELECT 
		BlogComment.Id,
		BlogComment.ParentCommentId,
		BlogComment.BlogId,
		BlogComment.Comment,
		AppUser.UserName,
		BlogComment.ApplicationUserID,
		BlogComment.PublishDate,
		BlogComment.UpdateDate,
		BlogComment.IsActive
	FROM 
	dbo.BlogComment AS BlogComment 
	INNER JOIN 
	dbo.ApplicationUser AS AppUser 
	ON BlogComment.ApplicationUserID = AppUser.Id;

CREATE TYPE [dbo].[AccountType] AS TABLE(
	[UserName] VARCHAR(20) NOT NULL,
	[NormalizeUserName] VARCHAR(20) NOT NULL,
	[Email] VARCHAR(30) NOT NULL,
	[NormalizeEmail] VARCHAR(30) NOT NULL,
	[FullName] VARCHAR(30) NULL,
	[PasswordHash] NVARCHAR(MAX) NOT NULL
);

CREATE TYPE [dbo].[PhotoType] AS TABLE(
	[PublicId] VARCHAR(50) NOT NULL,
	[ImageUrl] VARCHAR(250) NOT NULL,
	[Description] VARCHAR(30) NOT NULL
);

CREATE TYPE [dbo].[BlogType] AS TABLE(
	[BlogId] INT NOT NULL,
	[Title] VARCHAR(50) NOT NULL,
	[Content] VARCHAR(MAX) NOT NULL,
	[PhotoId] INT NULL
);

CREATE TYPE [dbo].[BlogCommentType] AS TABLE(
	[Id] INT NOT NULL,
	[ParentCommentId] INT NULL,
	[BlogId] INT NOT NULL,
	[Comment] VARCHAR(300) NOT NULL
);

CREATE OR ALTER PROCEDURE [dbo].[Account_GetByUsername]
	@NormalizeUserName VARCHAR(250)
AS 
BEGIN
    SET NOCOUNT ON;

	SELECT 
		   [Id]
		  ,[UserName]
		  ,[NormalizeUserName]
		  ,[Email]
		  ,[NormalizeEmail]
		  ,[FullName]
	FROM 
		[dbo].[ApplicationUser] AS AppUser
	WHERE 
		AppUser.[NormalizeUserName] = @NormalizeUserName;
END


CREATE OR ALTER PROCEDURE [dbo].[Account_Insert]
    @Account AccountType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[ApplicationUser]
           ([UserName],
            [NormalizeUserName],
            [Email],
            [NormalizeEmail],
            [FullName])
    SELECT 
           [UserName],
           [NormalizeUserName],
           [Email],
           [NormalizeEmail],
           [FullName]
    FROM @Account;

    SELECT CAST(SCOPE_IDENTITY() AS INT);
END


CREATE OR ALTER PROCEDURE [dbo].[Blog_Delete]
@BlogId INT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE [dbo].[BlogComment] 
	SET 
		[IsActive] = CONVERT(BIT, 0)
	WHERE 
		[BlogId] = @BlogId;

	UPDATE [dbo].[Blog] 
	SET 
		[IsActive] = CONVERT(BIT, 0)
	WHERE 
		[Id] = @BlogId;
END

CREATE OR ALTER PROCEDURE [dbo].[Get_Blog]
	@BlogId INT
AS 
BEGIN
	SET NOCOUNT ON;
	SELECT 
	   [Id]
      ,[ApplicationUserID]
      ,[UserName]
      ,[Title]
      ,[Content]
      ,[PhotoId]
      ,[PublishDate]
      ,[UpdateDate]
      ,[IsActive]
	FROM 
		[aggregate].[Blog] 
	WHERE 
		[IsActive] = CONVERT(BIT, 1) 
	AND 
		[Id] = @BlogId
END


CREATE OR ALTER PROCEDURE [dbo].[GetAll_Blog]
	@Offset INT,
	@PageSize INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT 
	   [Id]
      ,[ApplicationUserID]
      ,[UserName]
      ,[Title]
      ,[Content]
      ,[PhotoId]
      ,[PublishDate]
      ,[UpdateDate]
      ,[IsActive]
	FROM 
		[aggregate].[Blog] 
	WHERE 
		[IsActive] = CONVERT(BIT, 1)
	ORDER BY
		[Id]
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY;

	SELECT
		COUNT(*) 	
	FROM 
		[aggregate].[Blog] 
	WHERE 
		[IsActive] = CONVERT(BIT, 1)
END