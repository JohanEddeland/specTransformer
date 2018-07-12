function strWithFPI = getStringWithFPI(obj, str)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
strWithFPI = ['{' num2str(obj.fpiCounter) '}' str '{/' num2str(obj.fpiCounter) '}'];
obj.fpiCounter = obj.fpiCounter + 1;

end

