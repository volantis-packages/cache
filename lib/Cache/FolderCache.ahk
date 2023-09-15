class FolderCache extends FileCache {
    _existsSubPath := ""

    __New(tmpDir, stateObj, parentDir, cacheDirName := "", existsSubPath := "") {
        if (existsSubPath) {
            this._existsSubPath := this.ConvertPathToDestinationFormat(existsSubPath)
        }

        super.__New(tmpDir, stateObj, parentDir, cacheDirName)
    }

    ItemExists(path) {
        return super.ItemExists(path) && this.CacheDirExists(path)
    }

    CacheDirExists(path) {
        exists := DirExist(this.GetCachePath(path))

        if (exists && this._existsSubPath) {
            exists := FileExist(this.GetCachePath(path) . "\" . this._existsSubPath)
        }

        return exists
    }

    ReadItemAction(path) {
        return (this.ItemExists(path)) ? this.GetCachePath(path) : ""
    }

    /**
     * Caches a repository from the provided VCS url.
     */
    WriteItemAction(path, sourcePath) {
        path := this.GetCachePath(path)
        sourcePath := this.ConvertPathToDestinationFormat(sourcePath)
        isArchiveFile := this._IsArchiveFile(sourcePath)

        if (!isArchiveFile && !DirExist(sourcePath)) {
            throw DataException("Source path does not exist: " . sourcePath)
        }

        if (DirExist(path)) {
            DirDelete(path, true)
        }

        if (isArchiveFile) {
            return this._ExtractArchive(sourcePath, path)
        } else {
            DirCopy(sourcePath, path, true)
        }

        return true
    }

    _ExtractArchive(archiveFilePath, cachePath) {
        cachePath := this.GetCachePath(cachePath)

        try {
            archiveObj := ArchiveFileFactory.Create(archiveFilePath)
            archiveObj.Extract(cachePath)
        } catch Any as ex {
            throw DataException("Failed to extract archive file: " . archiveFilePath . "\n" . ex.Message)
        }

        return true
    }

    _IsArchiveFile(testPath) {
        return !!(testPath ~= ".*\.(zip|tar|gz|tgz|tar\.gz|tar\.bz2|tbz2|tar\.xz|txz|rar|7z)$")
    }

    /**
     * Deletes a cached repository.
     */
    RemoveItemAction(path) {
        path := this.GetCachePath(path)

        if (path != "" && DirExist(path)) {
            DirDelete(path)
        }

        super.RemoveItemAction(path)
    }

    ImportItemFromUrl(path, url, ref := "") {
        pathExt := RegExReplace(url, ".*\.(zip|tar|gz|tgz|tar\.gz|tar\.bz2|tbz2|tar\.xz|txz|rar|7z)$", "$1")

        if (!pathExt) {
            throw DataException("Unable to determine extension from archive URL: " . url)
        }

        pathUrl := this.ConvertUrlToPathName(this.SubStr(url, 1, -StrLen(pathExt)))
        tmpPath := this.tmpDir . "\" . pathUrl . "." . pathExt
        Download(url, tmpPath)
        this.WriteItem(path, tmpPath)
        return path
    }

    CopyItem(path, destination) {
        sourcePath := this.GetCachePath(path)

        if (path != "" && sourcePath != "" && destination != "" && sourcePath != destination) {
            DirCopy(sourcePath, destination, true)
        }

        return destination
    }

    GetCachedDownload(cachePath, downloadUrl := "") {
        if (downloadUrl == "") {
            downloadUrl := cachePath
            cachePath := this.ConvertUrlToPathName(downloadUrl)
        }

        return super.GetCachedDownload(cachePath, downloadUrl)
    }
}
