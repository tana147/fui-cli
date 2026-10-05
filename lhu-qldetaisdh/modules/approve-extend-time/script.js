function getChipColor(name) {
    switch (name) {
        case "W":
            return "info";
        case "C":
            return "success";
        case "P":
            return "blue light-2";
        case "R":
            return "error";
        default:
            return "secondary";
    }
}
function getStepIcon(name) {
    switch (name) {
        case "w": //W: WAIT
            return "mdi-information"
        case "C": //C: COMPLETED
            return "mdi-check-bold"
        case "P": //P:PROCESSING
            return "mdi-timer-sand"
        case "R": //R: REJECTED
            return "mdi-close-thick"
        default:
            return "water-boiler-alert"
    }
}