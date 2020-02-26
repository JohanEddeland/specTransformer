function fromToSTL(obj, component)
%FUNCTION   Description goes here.
%

thisParent = get(component, 'Parent');
ph = get(component,'PortHandles');
outportHandle = ph.Outport;

if isempty(get(outportHandle,'Name'))
    % This 'From' block hasn't yet had its output name
    % set by a 'Goto' block
    tag = get(component, 'GotoTag');
    gotoBlock = find_system(thisParent,'LookUnderMasks','On','SearchDepth',1,'BlockType','Goto','GotoTag',tag);
    gotoBlock = get_param(gotoBlock,'Handle');
    
    % Need to find the correct goto block
    correctGotoBlock = 1; % Index to use, standard is 1
    for tmpCounter = 1:length(gotoBlock)
        tmpGoto = gotoBlock{tmpCounter};
        tmpGotoPh = get(tmpGoto,'PortHandles');
        tmpGotoInputName = get(tmpGotoPh.Inport,'Name');
        if ~isempty(tmpGotoInputName)
            % We can use this one
            correctGotoBlock = tmpCounter;
            break
        end
    end
    try
        obj.gotoBlock = gotoBlock{correctGotoBlock};
    catch
        errorStruct.message = 'There is no Goto-block connected to the From-block.';
        errorStruct.identifier = 'fromToSTL:missingGotoBlock';
        error(errorStruct);
    end
    
    obj.atGotoBlock = 1;
    % Set the 'From' block as parent and set the 'GoTo'
    % block as child
    obj.systemHandle(end+1) = obj.gotoBlock;
    obj.parentHandle(end+1) = component;
    obj.timesVisited(end+1) = 1;
else
    % This 'From' block HAS had its output name set by
    % a 'Goto' block
    % Nothing needs to be done
end

end

