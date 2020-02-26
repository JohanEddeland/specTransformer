function logManyBlocks(obj, allBlocks)

for blk_counter = 1:length(allBlocks)
    tmpBlock = allBlocks{blk_counter};
    tmpHandle = get_param(tmpBlock, 'handle');
    
    % Only look at the name of THIS component, i.e. look at the name after
    % the last forward-slash.
    slashIndices = strfind(tmpBlock, '/');
    if isempty(slashIndices)
        continue
    end
    tmpBlock = tmpBlock(slashIndices(end)+1:end);
    tmpType = get(tmpHandle, 'BlockType');
    tmpMaskType = get(tmpHandle, 'MaskType');
    
    % Here, we can add specific subsystems that should be logged (we cannot
    % parse them, or it is not helpful to parse them to STL). 
    if strcmp(tmpType, 'Step')
        obj.logOneBlock(tmpHandle);
        
    elseif strcmp(tmpType, 'Lookup_n-D')
        obj.logOneBlock(tmpHandle);
        
    elseif strcmp(tmpType, 'S-Function') ...
            && isempty(strfind(get(tmpHandle, 'Tag'), 'Stateflow'))
        % An S-Function that is NOT part of Stateflow!
        % We cannot log Stateflow S-Functions (must log the Simulink
        % Subsystem around it instead. This is done below).
        obj.logOneBlock(tmpHandle);
        
    elseif strcmp(tmpType, 'S-Function') ...
            && ~isempty(strfind(get(tmpHandle, 'Tag'), 'Stateflow'))
        % Log the parent block. For Stateflow S-Functions, we cannot log
        % the S-Function itself. 
        parentBlock = get(tmpHandle, 'Parent');
        obj.logOneBlock(get_param(parentBlock, 'Handle'));
        
    elseif strcmp(tmpType, 'Fcn')
        % General function block
        % It may be the case that we want to specifically define an STL
        % formula for it
        obj.logOneBlock(tmpHandle);
        
    end
    
    
    
end

end

