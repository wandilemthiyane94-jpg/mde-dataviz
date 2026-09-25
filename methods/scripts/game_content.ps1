# Content for prototype/game.html, loaded by build_prototype_data.ps1.
# Every figure carries its source. Choices and the plain-language warning are illustrative, and labelled as such.
$game = [ordered]@{
  setting = 'A home near the river, eThekwini (Durban). A fictional household in a real place, with a real warning.'
  choices = @(
    [ordered]@{ id = 'washing'; label = 'Bring the washing in off the line'; live = $false },
    [ordered]@{ id = 'bed'; label = 'Charge your phone and go to bed'; live = $false },
    [ordered]@{ id = 'bridge'; label = "Drive across the low bridge to your mother's house"; live = $false },
    [ordered]@{ id = 'buckets'; label = 'Put buckets under the leaking roof'; live = $false },
    [ordered]@{ id = 'car'; label = 'Move the car up the road, then come back'; live = $false },
    [ordered]@{ id = 'leave'; label = 'Wake everyone and walk to the hall on the hill, now'; live = $true }
  )
  fixed_warning = 'Flood warning for your area tonight. The river will rise after 11pm and flood homes close to it. Leave now. Walk to the community hall on the hill. Do not drive across low bridges.'
  fixed_warning_note = 'Illustrative plain-language wording with an action and a destination. Not an issued warning.'
  braille_text = 'leave now. go to the hall on the hill.'
  sasl = [ordered]@{
    text = 'South Africa has 12 official languages. The 12th, South African Sign Language, was added when the President signed the Constitution Eighteenth Amendment on 19 July 2023.'
    sources = @('https://www.thepresidency.gov.za/president-cyril-ramaphosa-enact-sign-language-12th-official-language', 'https://www.parliament.gov.za/press-releases/na-approves-south-african-sign-language-12th-official-language')
  }
  l2 = [ordered]@{
    bars_title = 'Correctly understood a "tornado watch" (USA survey)'
    bars = @([ordered]@{ label = 'English speakers, English term'; v = 66 }, [ordered]@{ label = 'Spanish speakers, official Spanish term'; v = 38 })
    bars_source = 'Trujillo-Falcon et al. 2022, Bulletin of the American Meteorological Society, https://doi.org/10.1175/BAMS-D-22-0050.1'
    facts = @(
      [ordered]@{ text = 'Under stress, reading in a second language slows down. Reading in a first language does not.'; source = 'Rai, Loschky & Harris 2015, https://doi.org/10.1037/a0037591' },
      [ordered]@{ text = 'In noise (rain, wind, a crackling radio), non-native listeners understand speech worse, and the gap widens as conditions get worse.'; source = 'Garcia Lecumberri, Cooke & Cutler 2010, https://doi.org/10.1016/j.specom.2010.08.014' },
      [ordered]@{ text = 'Emotional words carry less force in a second language, so urgency is felt less.'; source = 'Harris, Aycicegi & Gleason 2003, https://doi.org/10.1017/S0142716403000286' }
    )
  }
  levels = [ordered]@{
    question = 'Your phone says ORANGE LEVEL 9 WARNING: DISRUPTIVE RAIN. What does "Level 9" mean?'
    options = @('A 9 in 10 chance of rain', '9 centimetres of rain', 'The 9th warning this season', 'How bad the impact could be, combined with how likely it is')
    answer = 3
    explain = 'SAWS levels (1 to 10) combine how severe the expected impact is with how likely it is. Red Level 10 is the highest. The warning never tells you what to do.'
    explain_source = 'data/forecasting_infrastructure.json (claim 7)'
    quotes = @(
      [ordered]@{ text = 'What is a level 4 and what does that mean?'; who = "groundWork's Thalia Erwin, KwaZulu-Natal, Sept 2026 (IOL)"; source = 'https://iol.co.za/news/south-africa/2026-09-19-kzn-heavy-rain-tests-whether-flood-warnings-reach-vulnerable-communities/' },
      [ordered]@{ text = 'Although some of them may have heard about the level 10 weather warning in the lead-up to the disaster, very few had an idea of what this meant.'; who = 'Daily Maverick on the Limpopo floods, Feb 2026'; source = 'https://www.dailymaverick.co.za/article/2026-02-16-anatomy-of-a-disaster-how-sas-warning-systems-stalled-during-the-floods/' },
      [ordered]@{ text = '85% did not expect very severe flooding and 46% did not know what to do.'; who = 'Warned residents, Ahr valley floods 2021, Germany (Thieken et al., NHESS 2023)'; source = 'https://nhess.copernicus.org/articles/23/973/2023/' }
    )
  }
  world = @(
    [ordered]@{ iso = '508'; place = 'Mozambique'; before = 'Cyclone Idai 2019: more than 600 dead. Warnings mostly in Portuguese, which only half the population speaks.'; after = 'Cyclone Freddy 2023: fewer than 200 dead. Community radio in local languages, and a free 3-2-1 phone line.'; bd = 600; ad = 200
      sources = @('https://translatorswithoutborders.org/in-need-of-words-using-local-languages-improves-comprehension-for-people-affected-by-cyclone-idai-in-beira-mozambique/', 'https://wmo.int/site/science-action/weather-forecasts-and-early-warnings/mozambiques-life-saving-early-warning-systems') },
    [ordered]@{ iso = '050'; place = 'Bangladesh'; before = 'Bhola cyclone 1970: about 300,000 dead.'; after = 'Cyclone Amphan 2020: 26 dead. About 76,000 volunteers turn forecasts into spoken Bangla, with megaphones and flags.'; bd = 300000; ad = 26
      sources = @('https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9657222/', 'https://reliefweb.int/report/bangladesh/bangladesh-cyclone-amphan-final-report-n-mdrbd024') },
    [ordered]@{ iso = '356'; place = 'Odisha, India'; before = 'Super cyclone 1999: more than 10,000 dead.'; after = 'Cyclone Fani 2019: several dozen dead. Loudspeakers in the local language; 1.2 million+ evacuated.'; bd = 10000; ad = 42
      sources = @('https://www.unescap.org/blog/storm-strength-odishas-zero-casualty-model-community-centered-disaster-resilience', 'https://www.preventionweb.net/news/un-praises-almost-pinpoint-accuracy-forecast-based-warnings-clean-underway-india-and') },
    [ordered]@{ iso = '608'; place = 'Philippines'; before = 'Typhoon Haiyan 2013: about 6,300 dead. Many did not understand the English term "storm surge".'; after = 'Now paired with the Filipino "daluyong ng bagyo" and surge heights in metres.'; bd = $null; ad = $null
      sources = @('https://www.devex.com/news/storm-surge-lost-in-translation-and-interpretation-82311') },
    [ordered]@{ iso = '840'; place = 'New York, USA'; before = 'Hurricane Ida 2021: 11 basement deaths, nearly all Asian immigrants. Alerts in English and Spanish only.'; after = 'Basement flood alerts in 14 languages since April 2023.'; bd = $null; ad = $null
      sources = @('https://www.nbcnews.com/news/asian-america/ida-s-forgotten-victims-nearly-all-storm-s-basement-deaths-n1281670', 'https://www.cbsnews.com/newyork/news/new-york-city-basement-flooding-alerts/') },
    [ordered]@{ iso = '036'; place = 'Northern Territory, Australia'; before = 'Cyclone Trevor 2019: English-only updates caused panic and self-evacuation at Ngukurr.'; after = 'The Bureau of Meteorology now works with Yolngu Radio and Aboriginal interpreters.'; bd = $null; ad = $null
      sources = @('https://www.abc.net.au/news/2019-04-06/cyclone-trevor-translations-ngukurr-panic-nt-police-government/10976520', 'https://www.bom.gov.au/news-and-media/working-with-first-nations-interpreters-during-severe-weather') },
    [ordered]@{ iso = '710'; place = 'South Africa'; before = 'Official warnings in English. 64% of the deaths we can place were in places where fewer than 1 in 10 people speak English as a first language.'; after = 'No change yet.'; bd = $null; ad = $null; home = $true
      sources = @('data/warning_language.json', 'data/death_site_language_flat.json') }
  )
  world_caveat = 'Different storms and many changes besides language. Not a controlled comparison.'
}
