<Query Kind="Program" />

void Main()
{
	var metaItem = @"https://fasttrak.dips.no/MetaItem.asp";
	var metaFormItem = @"https://fasttrak.dips.no/MetaFormItem.asp";

	var exclude =
		XDocument.Load(metaItem)
			.Elements("MetaItem")
			.Elements("Row")
			.Select(e => e.Attribute("VarName").Value.ToUpper())
			.ToList();

	XDocument.Load(metaFormItem)
		.Elements("MetaFormItem")
		.Elements("Row")
		.Where(e => e.Attribute("Expression") != null || e.Attribute("MinExpression") != null || e.Attribute("MaxExpression") != null)
		.SelectMany(e => new List<string> { e.Attribute("Expression")?.Value, e.Attribute("MinExpression")?.Value, e.Attribute("MaxExpression")?.Value })
		.Where(e => !string.IsNullOrEmpty(e))
		.SelectMany(e => e.Split(new char[] { ' ', '+', '*', '/', '-', ')', '(' }))
		.Where(e => Regex.IsMatch(e.ToUpper(), @"[A-Za-z][\w\._]+") && !Regex.IsMatch(e.ToUpper(), @"^VAR\d{4}$|_SCORE$|^(ABS|EXP|TRUNC)$|^ICD10_.*_HX$|^ATC_\w{7}$") )
		.Select(e => e.ToUpper())
		.Distinct()
		.Where(e=> !exclude.Any(i=>e.Equals(i)) )
		.OrderBy(e=>e)
		.Dump();
}

// Define other methods and classes herse