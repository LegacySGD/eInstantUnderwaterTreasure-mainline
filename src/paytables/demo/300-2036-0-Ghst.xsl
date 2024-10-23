<?xml version="1.0" encoding="UTF-8"?><xsl:stylesheet version="1.0" exclude-result-prefixes="java" extension-element-prefixes="my-ext" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:my-ext="ext1">
<xsl:import href="HTML-CCFR.xsl"/>
<xsl:output indent="no" method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/">
<xsl:apply-templates select="*"/>
<xsl:apply-templates select="/output/root[position()=last()]" mode="last"/>
<br/>
</xsl:template>
<lxslt:component prefix="my-ext" functions="formatJson">
<lxslt:script lang="javascript">
					
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
    for (var i = 0; i &lt; nameAndCollectList.length; ++i) {
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
    while (index &lt; translations.item(0).getChildNodes().getLength()) {
        var childNode = translations.item(0).getChildNodes().item(index);
        registerDebugText(childNode.getAttribute("key") + ": " + childNode.getAttribute("value"));
        index += 2;
    }

    // !DEBUG
    //registerDebugText("Translating the text \"softwareId\" to \"" + getTranslationByName("softwareId", translations) + "\"");
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Output winning numbers table.
    var r = [];
    r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');

    // Header and Basic Outcomes table
    r.push('&lt;tr&gt;');
    r.push('&lt;td class="tablehead"&gt;');
    r.push(getTranslationByName("gems", translations));
    r.push('&lt;/td&gt;');

    r.push('&lt;td class="tablehead"&gt;');
    r.push(getTranslationByName("numberCollected", translations));
    r.push('&lt;/td&gt;');

    r.push('&lt;td class="tablehead"&gt;');
    r.push(getTranslationByName("prize", translations));
    r.push('&lt;/td&gt;');
    r.push('&lt;/tr&gt;');

    for (var prize = 0; prize &lt; prizeNamesList.length; ++prize) {
        registerDebugText("PrizeNamesList[" + prize + "]: " + prizeNamesList[prize]);
        r.push('&lt;tr&gt;');
        if (isNaN(prizeNamesList[prize])) {
            r.push('&lt;td class="tablebody"&gt;');
            r.push(getTranslationByName(prizeNamesList[prize], translations));
            r.push('&lt;/td&gt;');

            var numCollected = countPrizeCollections(prizeNamesList[prize], scenario);
            registerDebugText(getTranslationByName(prizeNamesList[prize], translations) + " collection count: " + numCollected);
            r.push('&lt;td class="tablebody"&gt;');
            r.push(numCollected + "/" + collectionsList[prize]);
            r.push('&lt;/td&gt;');

            r.push('&lt;td class="tablebody"&gt;');
            if (numCollected == collectionsList[prize]) {
                r.push(prizeValues[prize]);
            }
            r.push('&lt;/td&gt;');
        }
        r.push('&lt;/tr&gt;');
    }
    r.push('&lt;/table&gt;');


    r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');

    // Header and Basic Outcomes table
    r.push('&lt;tr&gt;');
    r.push('&lt;td class="tablehead"&gt;');
    r.push(getTranslationByName("dragonsLair", translations));
    r.push('&lt;/td&gt;');

    r.push('&lt;td class="tablehead"&gt;');
    r.push(getTranslationByName("prize", translations));
    r.push('&lt;/td&gt;');
    r.push('&lt;/tr&gt;');

    for (var iw = 0; iw &lt; instantWinPrizes.length; ++iw) {
        var numCollected = countPrizeCollections(instantWinPrizes[iw], scenario);

        r.push('&lt;tr&gt;');
        r.push('&lt;td class="tablebody"&gt;');
        r.push(getTranslationByName(instantWinPrizes[iw], translations));
        r.push('&lt;/td&gt;');

        var numCollected = countPrizeCollections(instantWinPrizes[iw], scenario);
        registerDebugText("Instant Win " + instantWinPrizes[iw] + " collection count: " + numCollected);

        r.push('&lt;td class="tablebody"&gt;');
        if (numCollected == 1) {
            r.push(prizeValues[prizeNamesList.length + iw]);
        }
        r.push('&lt;/td&gt;');
        r.push('&lt;/tr&gt;');
    }
    r.push('&lt;/table&gt;');


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // !DEBUG OUTPUT TABLE

    if (debugFlag) {
        // DEBUG TABLE
        //////////////////////////////////////
        r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');
        for (var idx = 0; idx &lt; debugFeed.length; ++idx) {
            if (debugFeed[idx] == "")
                continue;
            r.push('&lt;tr&gt;');
            r.push('&lt;td class="tablebody"&gt;');
            r.push(debugFeed[idx]);
            r.push('&lt;/td&gt;');
            r.push('&lt;/tr&gt;');
        }
        r.push('&lt;/table&gt;');
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
    for (var i = 0; i &lt; splitScenario.length; ++i) {
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
    for (var char = 0; char &lt; scenario.length; ++char) {
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
    while (index &lt; translationNodeSet.item(0).getChildNodes().getLength()) {
        var childNode = translationNodeSet.item(0).getChildNodes().item(index);
        if (childNode.name == "phrase" &amp;&amp; childNode.getAttribute("key") == keyName) {
            return childNode.getAttribute("value");
        }
        index += 1;
    }
}
					
				</lxslt:script>
</lxslt:component>
<xsl:template match="root" mode="last">
<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
<tr>
<td valign="top" class="subheader">
<xsl:value-of select="//translation/phrase[@key='totalWager']/@value"/>
<xsl:value-of select="': '"/>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</td>
</tr>
<tr>
<td valign="top" class="subheader">
<xsl:value-of select="//translation/phrase[@key='totalWins']/@value"/>
<xsl:value-of select="': '"/>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</td>
</tr>
</table>
</xsl:template>
<xsl:template match="//Outcome">
<xsl:if test="OutcomeDetail/Stage = 'Scenario'">
<xsl:call-template name="History.Detail"/>
</xsl:if>
<xsl:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
<xsl:call-template name="History.Detail"/>
</xsl:if>
</xsl:template>
<xsl:template name="History.Detail">
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
<tr>
<td class="tablebold" background="">
<xsl:value-of select="//translation/phrase[@key='transactionId']/@value"/>
<xsl:value-of select="': '"/>
<xsl:value-of select="OutcomeDetail/RngTxnId"/>
</td>
</tr>
</table>
<xsl:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())"/>
<xsl:variable name="translations" select="lxslt:nodeset(//translation)"/>
<xsl:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)"/>
<xsl:variable name="prizeTable" select="lxslt:nodeset(//lottery)"/>
<xsl:variable name="convertedPrizeValues">
<xsl:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
</xsl:variable>
<xsl:variable name="prizeNames">
<xsl:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
</xsl:variable>
<xsl:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes"/>
</xsl:template>
<xsl:template match="prize" mode="PrizeValue">
<xsl:text>|</xsl:text>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="text()"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</xsl:template>
<xsl:template match="description" mode="PrizeDescriptions">
<xsl:text>,</xsl:text>
<xsl:value-of select="text()"/>
</xsl:template>
<xsl:template match="text()"/>
</xsl:stylesheet>
