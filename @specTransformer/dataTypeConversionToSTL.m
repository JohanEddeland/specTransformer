function dataTypeConversionToSTL(obj, component)
%FUNCTION   Description goes here.
%

% Dont change the formula for this block
% Find the input names. If any of them are not
% 'sub'-names, rename them so they can be used with
% eval
inputNames = obj.getInputNames(component);
inputName = inputNames{1};

ph = get_param(component,'PortHandles');
outportHandle = ph.Outport;
set(outportHandle,'Name',inputName);

end

