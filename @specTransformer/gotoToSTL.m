function gotoToSTL(obj, component)
%FUNCTION   Description goes here.
%

% Just propagate the signal to the corresponding 'From'
% blocks

% The tag of this block is 'thisGotoTag'
thisGotoTag = get(component,'GotoTag');

% Find the input names. If any of them are not
% 'sub'-names, rename them so they can be used with
% eval
inputNames = obj.getInputNames(component);

% The input signal to the goto block is 'inp'
inp = inputNames{1};

thisParent = get(component, 'Parent');

% Get all the corresponding 'From' blocks
fromList = find_system(thisParent,'SearchDepth',1,'BlockType','From');
for fromCounter=1:length(fromList)
    fromBlock = fromList{fromCounter};
    fromBlock = get_param(fromBlock,'Handle');
    
    % The tag of the 'From' block is fromGotoTag
    fromGotoTag = get(fromBlock,'GotoTag');
    if strcmp(fromGotoTag,thisGotoTag)
        % If they have the same GotoTag, propagate the
        % signal name to the 'From' block
        ph = get(fromBlock,'PortHandles');
        outportHandle = ph.Outport;
        set(outportHandle,'Name',inp);
    end
end

end

