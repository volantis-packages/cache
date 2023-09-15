class CacheBase {
    tmpDir := ""
    stateObj := ""

    __New(tmpDir, stateObj) {
        if (!tmpDir) {
            throw FileSystemException("A temporary directory name or full path is required")
        }

        if (!InStr(tmpDir, ":") && SubStr(tmpDir, 1, 1) != "\") {
            tmpDir := A_Temp . "\" . tmpDir
        }

        this.tmpDir := tmpDir
        this.stateObj := stateObj
    }

    IsCacheOutdated() {
        return (!this.stateObj || this.stateObj.IsStateOutdated())
    }

    ItemExists(reference) {
        return this.stateObj.Exists(reference)
    }

    GetItemTimestamp(reference) {
        return this.stateObj.GetTimestamp(reference)
    }

    WriteItem(reference, content, responseCode := "") {
        if (this.WriteItemAction(reference, content)) {
            this.stateObj.SetItem(reference, responseCode)
        }
    }

    ReadItem(reference) {
        content := ""

        if (this.stateObj.Exists(reference)) {
            content := this.ReadItemAction(reference)
        }

        return content
    }

    SetNotFound(reference) {
        this.stateObj.SetNotFoundItem(reference)
    }

    GetResponseCode(reference) {
        this.stateObj.GetResponseCode(reference)
    }

    SetResponseCode(reference, responseCode) {
        this.stateObj.SetResponseCode(reference, responseCode)
    }

    RemoveItem(reference) {
        if (this.stateObj.Exists(reference)) {
            this.RemoveItemAction(reference)
            this.stateObj.RemoveItem(reference)
        }
    }

    FlushCache(force := false) {
        flushed := false

        if (force || this.IsCacheOutdated()) {
            flushed := this.FlushCacheAction(force)
        }

        if (flushed) {
            this.stateObj.ClearItems()
        }

        return flushed
    }

    ImportItemFromUrl(reference, url) {
        tempFile := this.tmpDir . "\cacheDownload"
        DirCreate(this.tmpDir)
        Download(url, tempFile)
        content := FileRead(tempFile)

        if (FileExist(tempFile)) {
            FileDelete(tempFile)
        }

        this.WriteItem(reference, content)

        return content
    }

    GetCacheAge(reference) {
        return this.stateObj.GetCacheAge(reference)
    }

    CopyItem(reference, destination) {
        if (this.ItemExists(reference)) {
            content := this.GetItem(reference)
            this.WriteItem(destination, content)
        }

        return destination
    }

    ItemNeedsUpdate(reference, maxCacheAge := "") {
        return this.stateObj.IsExpired(reference, maxCacheAge)
    }

    /**
    * ABSTRACT METHODS
    */

    WriteItemAction(reference, content) {
        throw(MethodNotImplementedException("CacheBase", "WriteItemAction"))
    }

    ReadItemAction(reference) {
        throw(MethodNotImplementedException("CacheBase", "ReadItemAction"))
    }

    RemoveItemAction(reference) {
        throw(MethodNotImplementedException("CacheBase", "RemoveItemAction"))
    }

    FlushCacheAction(force := false) {
        throw(MethodNotImplementedException("CacheBase", "FlushCacheAction"))
    }
}
