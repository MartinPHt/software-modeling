CREATE DATABASE MusicStreaming;
GO

USE MusicStreaming;
GO

CREATE TABLE Artist (
    artist_ID INT PRIMARY KEY IDENTITY,
    name NVARCHAR(255) NOT NULL,
    bio NVARCHAR(MAX),
    nationality NVARCHAR(100)
);

CREATE TABLE Album (
    album_ID INT PRIMARY KEY IDENTITY,
    title NVARCHAR(255) NOT NULL,
    duration INT,
    release_date DATE,
    artist_ID INT NOT NULL,
    FOREIGN KEY (artist_ID) REFERENCES Artist(artist_ID)
);

CREATE TABLE Song (
    song_ID INT PRIMARY KEY IDENTITY,
    title NVARCHAR(255) NOT NULL,
    release_date DATE,
    duration INT,
    artist_ID INT NOT NULL,
    album_ID INT,
    FOREIGN KEY (artist_ID) REFERENCES Artist(artist_ID),
    FOREIGN KEY (album_ID) REFERENCES Album(album_ID)
);

CREATE TABLE [User] (
    user_ID INT PRIMARY KEY IDENTITY,
    user_name NVARCHAR(255) NOT NULL,
    password NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    date_of_creation DATE NOT NULL,
    nationality NVARCHAR(100),
    date_of_birth DATE
);

CREATE TABLE Subscription_Type (
    subscription_type_ID INT PRIMARY KEY IDENTITY,
    name NVARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Subscription (
    subscription_ID INT PRIMARY KEY IDENTITY,
    user_ID INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    subscription_type_ID INT NOT NULL,
    FOREIGN KEY (user_ID) REFERENCES [User](user_ID),
    FOREIGN KEY (subscription_type_ID) REFERENCES Subscription_Type(subscription_type_ID)
);

CREATE TABLE Playlist (
    playlist_ID INT PRIMARY KEY IDENTITY,
    title NVARCHAR(255) NOT NULL,
    created_on DATE NOT NULL,
    user_ID INT NOT NULL,
    FOREIGN KEY (user_ID) REFERENCES [User](user_ID)
);

CREATE TABLE Playlist_Song (
    playlist_ID INT NOT NULL,
    song_ID INT NOT NULL,
    PRIMARY KEY (playlist_ID, song_ID),
    FOREIGN KEY (playlist_ID) REFERENCES Playlist(playlist_ID),
    FOREIGN KEY (song_ID) REFERENCES Song(song_ID)
);
GO

CREATE PROCEDURE AddNewSong
    @title NVARCHAR(255),
    @release_date DATE,
    @duration INT,
    @artist_ID INT,
    @album_ID INT = NULL
AS
BEGIN
    INSERT INTO Song (title, release_date, duration, artist_ID, album_ID)
    VALUES (@title, @release_date, @duration, @artist_ID, @album_ID);
END;
GO

CREATE FUNCTION GetPlaylistDuration(@playlist_ID INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_duration INT;

    SELECT @total_duration = SUM(duration)
    FROM Playlist_Song PS
    JOIN Song S ON PS.song_ID = S.song_ID
    WHERE PS.playlist_ID = @playlist_ID;

    RETURN @total_duration;
END;
GO

CREATE TRIGGER UpdateAlbumDuration
ON Song
AFTER INSERT, DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE Album
        SET duration = (
            SELECT SUM(duration)
            FROM Song
            WHERE Song.album_ID = Album.album_ID
        )
        WHERE album_ID IN (SELECT DISTINCT album_ID FROM inserted);
    END;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE Album
        SET duration = (
            SELECT SUM(duration)
            FROM Song
            WHERE Song.album_ID = Album.album_ID
        )
        WHERE album_ID IN (SELECT DISTINCT album_ID FROM deleted);
    END;
END;
GO