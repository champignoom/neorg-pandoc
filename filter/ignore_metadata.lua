function Block(elem)
    if elem.attr and elem.attr.classes[1] == "document.meta" then
        return {}
    end
    return elem
end
