function sortFileName(str) {
    if (str.length > 20) {
        str = str.substring(0, 20) + "...";
    }
    return str
}