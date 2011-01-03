class TowerPlayerInput extends PlayerInput;

/** I predict this'll be painfully slow. If you use it definitely store the result! */
function name GetKeyFromCommand(string Command)
{
	local KeyBind Bind;
	foreach Bindings(Bind)
	{
		if(Bind.Command == Command)
		{
			return Bind.Name;
		}
	}
	return '';
}