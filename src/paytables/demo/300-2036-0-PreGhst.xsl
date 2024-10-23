<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson">
				<lxslt:script lang="javascript">
					<![CDATA[
// Limited to 50 strings of Debuging
var debugFeed = [];
var debugFlag = false;

// Format instant win JSON results.
// @param jsonContext String JSON results to parse and display.
// @param translation Set of Translations for the game.
function formatJson(jsonContext, translations, prizeTable, convertedPrizeValues, prizeNamesDesc) {
    var scenario = filterBonusRound(getScenario(jsonContext));
    var nameAndCollectList = (prizeNamesDesc.substring(1)).split(',');
    var prizeValues = (convertedPrizeValues.substring(1)).split('|');

    registerDebugText("Scenario: " + scenario);
    registerDebugText("Character in scenario at [3]: " + scenario[3]);

    registerDebugText("Collect List: " + nameAndCollectList);

    var prizeNamesList = [];
    var collectionsList = [];
    var instantWinPrizes = [];
    // length - 1 to omit Non Win
    for (var i = 0; i < nameAndCollectList.length; ++i) {
        var desc = nameAndCollectList[i];
        if (desc[0] != 'I') {
            prizeNamesList.push(desc[desc.length - 1]);
            collectionsList.push(desc.slice(0, desc.length - 1));
        } else {
            instantWinPrizes.push(desc[desc.length - 1]);
        }
    }

    registerDebugText("Prize Names: " + prizeNamesList);
    registerDebugText("Collection Counts: " + collectionsList);
    registerDebugText("Instant Wins: " + instantWinPrizes);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////          
    // Print Translation Table to !DEBUG
    var index = 1;
    registerDebugText("Translation Table");
    while (index < translations.item(0).getChildNodes().getLength()) {
        var childNode = translations.item(0).getChildNodes().item(index);
        registerDebugText(childNode.getAttribute("key") + ": " + childNode.getAttribute("value"));
        index += 2;
    }

    // !DEBUG
    //registerDebugText("Translating the text \"softwareId\" to \"" + getTranslationByName("softwareId", translations) + "\"");
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Output winning numbers table.
    var r = [];
    r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');

    // Header and Basic Outcomes table
    r.push('<tr>');
    r.push('<td class="tablehead">');
    r.push(getTranslationByName("gems", translations));
    r.push('</td>');

    r.push('<td class="tablehead">');
    r.push(getTranslationByName("numberCollected", translations));
    r.push('</td>');

    r.push('<td class="tablehead">');
    r.push(getTranslationByName("prize", translations));
    r.push('</td>');
    r.push('</tr>');

    for (var prize = 0; prize < prizeNamesList.length; ++prize) {
        registerDebugText("PrizeNamesList[" + prize + "]: " + prizeNamesList[prize]);
        r.push('<tr>');
        if (isNaN(prizeNamesList[prize])) {
            r.push('<td class="tablebody">');
            r.push(getTranslationByName(prizeNamesList[prize], translations));
            r.push('</td>');

            var numCollected = countPrizeCollections(prizeNamesList[prize], scenario);
            registerDebugText(getTranslationByName(prizeNamesList[prize], translations) + " collection count: " + numCollected);
            r.push('<td class="tablebody">');
            r.push(numCollected + "/" + collectionsList[prize]);
            r.push('</td>');

            r.push('<td class="tablebody">');
            if (numCollected == collectionsList[prize]) {
                r.push(prizeValues[prize]);
            }
            r.push('</td>');
        }
        r.push('</tr>');
    }
    r.push('</table>');


    r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');

    // Header and Basic Outcomes table
    r.push('<tr>');
    r.push('<td class="tablehead">');
    r.push(getTranslationByName("dragonsLair", translations));
    r.push('</td>');

    r.push('<td class="tablehead">');
    r.push(getTranslationByName("prize", translations));
    r.push('</td>');
    r.push('</tr>');

    for (var iw = 0; iw < instantWinPrizes.length; ++iw) {
        var numCollected = countPrizeCollections(instantWinPrizes[iw], scenario);

        r.push('<tr>');
        r.push('<td class="tablebody">');
        r.push(getTranslationByName(instantWinPrizes[iw], translations));
        r.push('</td>');

        var numCollected = countPrizeCollections(instantWinPrizes[iw], scenario);
        registerDebugText("Instant Win " + instantWinPrizes[iw] + " collection count: " + numCollected);

        r.push('<td class="tablebody">');
        if (numCollected == 1) {
            r.push(prizeValues[prizeNamesList.length + iw]);
        }
        r.push('</td>');
        r.push('</tr>');
    }
    r.push('</table>');


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // !DEBUG OUTPUT TABLE

    if (debugFlag) {
        // DEBUG TABLE
        //////////////////////////////////////
        r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
        for (var idx = 0; idx < debugFeed.length; ++idx) {
            if (debugFeed[idx] == "")
                continue;
            r.push('<tr>');
            r.push('<td class="tablebody">');
            r.push(debugFeed[idx]);
            r.push('</td>');
            r.push('</tr>');
        }
        r.push('</table>');
    }

    return r.join('');
}

// Input: Json document string containing 'scenario' at root level.
// Output: Scenario value.
function getScenario(jsonContext) {
    // Parse json and retrieve scenario string.
    var jsObj = JSON.parse(jsonContext);
    var scenario = jsObj.scenario;
    // Trim null from scenario string.
    scenario = scenario.replace(/\0/g, '');
    return scenario;
}

function filterBonusRound(scenario) {
    var simpleCollections = "";
    var splitScenario = scenario.split(",");
    for (var i = 0; i < splitScenario.length; ++i) {
        registerDebugText(splitScenario[i].toString());
        if (splitScenario[i].charAt(0) == "X") {
            var bonus = splitScenario[i].split(":");
            simpleCollections += bonus[1];
        } else {
            simpleCollections += splitScenario[i];
        }
    }
    return simpleCollections;
}

function countPrizeCollections(prizeName, scenario) {
    registerDebugText("Checking for prize in scenario: " + prizeName);
    var count = 0;
    for (var char = 0; char < scenario.length; ++char) {
        if (prizeName == scenario[char]) {
            count++;
        }
    }
    return count;
}

////////////////////////////////////////////////////////////////////////////////////////
function registerDebugText(debugText) {
    debugFeed.push(debugText);
}

/////////////////////////////////////////////////////////////////////////////////////////
function getTranslationByName(keyName, translationNodeSet) {
    var index = 1;
    while (index < translationNodeSet.item(0).getChildNodes().getLength()) {
        var childNode = translationNodeSet.item(0).getChildNodes().item(index);
        if (childNode.name == "phrase" && childNode.getAttribute("key") == keyName) {
            return childNode.getAttribute("value");
        }
        index += 1;
    }
}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="History.Detail" />
				</x:if>
				<x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
					<x:call-template name="History.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="History.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>

				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<x:variable name="convertedPrizeValues">

					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
