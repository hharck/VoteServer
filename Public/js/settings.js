function update(id, t, storedVal) {
    const existingVal = t.value

    var equal = false;
    if (t.type == "checkbox") {
        equal = (t.checked == storedVal);
    } else {
        equal = (existingVal == storedVal);
    }
    
    var element = document.getElementById("reset-" + id);
    element.hidden = equal
}

function buttonWasReset(id, defaultValue) {
    var button = document.getElementById("reset-" + id);
    button.hidden = true;
    
    var input = document.getElementById(id);
    
    if (input.type == "checkbox") {
        input.checked = defaultValue;
    } else {
        input.value = defaultValue;
    }
    
    
}
