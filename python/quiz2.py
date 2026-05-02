
import random, sql
from typing import Any, List

# res = sql.read("""SELECT name FROM drugGeneric
#     WHERE name <> 'diltiazem'
#     ORDER BY RANDOM()
#     LIMIT 10""")

# for element in res.fetchall():
#     print(element)


def genericToBrand(string: str, disNum: int = 0):

    # Choose a random generic drug name to test
    res = sql.curr().execute("""
        SELECT id, base FROM drug
        ORDER BY RANDOM()
        LIMIT 1""")
    drugId, drugBase = res.fetchone()

    # choose a random generic drug name
    res = sql.curr().execute("SELECT name FROM drugGeneric WHERE drugId = ?", (drugId,))
    genericName = res.fetchone()

    question = string % genericName

    # Choose the correct brand name
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId = ?", (drugId,))
    brandNames = [r[0] for r in res.fetchall()]
    print(brandNames)
    answer = random.choice(brandNames)

    # Choose three distractors
    res = sql.curr().execute("""
        SELECT name FROM drugBrand
        WHERE drugId NOT IN (SELECT id FROM drug WHERE base = ?)
        ORDER BY RANDOM()
        LIMIT 3
        """, (drugBase,))

    choices = [r[0] for r in res.fetchall()]

    if disNum > 0:
        # replace number with different brand distractors
        res = sql.curr().execute("SELECT brand FROM distractor ORDER BY RANDOM() LIMIT ?", (disNum,))

        replacements = [r[0] for r in res.fetchall()]
        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]


    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)


def genericToBrandAndUse(string: str, disNum: int = 0):

    # Choose a random generic drug name to test
    res = sql.curr().execute("SELECT * FROM drugGeneric ORDER BY RANDOM() LIMIT 1")
    drugId, inQuestion = res.fetchone()

    res = sql.curr().execute("SELECT use FROM drugUse WHERE drugId = ? ORDER BY RANDOM() LIMIT 1", (drugId,))
    use = res.fetchone()[0]
    question = string % inQuestion

    # Choose the correct brand name
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId = ? ", (drugId,))
    brandNames = [r[0] for r in res.fetchall()]
    answer = random.choice(brandNames) + ", " + use

    choices = []
    for _ in range(3):
        # Choose three distractors
        res = sql.read(f"""
            SELECT name, drugId FROM drugBrand
            WHERE drugId <> {drugId}
            ORDER BY RANDOM()
            LIMIT 1
            """)
        name, distractorId = res.fetchone()

        res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {distractorId} ORDER BY RANDOM() LIMIT 1")
        distractorUse = res.fetchone()[0]
        distractor = name + ", " + distractorUse
        choices.append(distractor)

    # choices = [r[0] for r in res.fetchall()]

    if disNum > 0:
        # replace number with different brand distractors that do not have same use in distractorUse
        res = sql.curr().execute("SELECT id FROM distractor WHERE id NOT IN (SELECT distractorId FROM distractorUse WHERE use = ?) ORDER BY RANDOM() LIMIT ?", (use, disNum,))

        replacements = []

        # get brand and use for each distractor
        drugIds = [r[0] for r in res.fetchall()]
        for id in drugIds:
            res = sql.curr().execute("SELECT brand FROM distractor WHERE id = ?", (id,))
            name = res.fetchone()[0]

            res = sql.curr().execute("SELECT use FROM distractorUse WHERE distractorId = ? ORDER BY RANDOM() LIMIT 1", (id,))
            distractorUse = res.fetchone()[0]

            distractor = name + ", " + distractorUse

            replacements.append(distractor)

        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]

    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)

def brandToGeneric(string: str, disNum: int = 0):

    # get a random drug
    res = sql.curr().execute("""
        SELECT id, base FROM drug
        ORDER BY RANDOM()
        LIMIT 1""")
    drugId, drugBase = res.fetchone()

    # print("chosen drug brand names")
    # res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId = ?", (drugId,))
    # print(res.fetchall())
    # print("chosen drug generic names")
    # res = sql.curr().execute("SELECT name FROM drugGeneric WHERE drugId = ?", (drugId,))
    # print(res.fetchall())
    # print("chosen drug base")
    # print(drugBase)
    # print("chosen drug base other brands")
    # res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId IN (SELECT id FROM drug WHERE base = ?)", (drugBase,))
    # print(res.fetchall())
    # print("chosen drug base other generic")
    # res = sql.curr().execute("SELECT name FROM drugGeneric WHERE drugId IN (SELECT id FROM drug WHERE base = ?)", (drugBase,))
    # print(res.fetchall())

    # get the drug's brand name
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId = ? ORDER BY RANDOM() LIMIT 1", (drugId,))
    inQuestion = res.fetchone()

    # get a generic drug name from the brand
    res = sql.curr().execute("SELECT name FROM drugGeneric WHERE drugId = ?", (drugId,))
    generic = [r[0] for r in res.fetchall()]
    answer = random.choice(generic)

    # choose three distractor generic drugs that do not have the same base
    res = sql.curr().execute("""
        SELECT name FROM drugGeneric
        WHERE drugId NOT IN (SELECT id FROM drug WHERE base = ?)
        ORDER BY RANDOM()
        LIMIT 3
        """, (drugBase,))
    choices = [r[0] for r in res.fetchall()]

    if disNum > 0:
        # replace number with different generic distractors
        res = sql.curr().execute("SELECT generic FROM distractor ORDER BY RANDOM() LIMIT ?", (disNum,))

        replacements = [r[0] for r in res.fetchall()]
        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]

    choices.append(answer)

    random.shuffle(choices)

    return (string % inQuestion, choices, answer)

def genericToNotBrand(string: str):

    # get a drugId with at least 3 brand names
    res = sql.curr().execute("SELECT drugId FROM drugBrand GROUP BY drugId HAVING COUNT (*) >= 3 ORDER BY RANDOM() LIMIT 1")
    drugId = res.fetchone()[0]

    # get a generic name for the drugId
    res = sql.curr().execute("SELECT name FROM drugGeneric WHERE drugId = ? ORDER BY RANDOM() LIMIT 1", (drugId,))
    inQuestion = res.fetchone()[0]

    # get three brand names for the drugId
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId = ? ORDER BY RANDOM() LIMIT 3", (drugId,))
    choices = [r[0] for r in res.fetchall()]

    # get a distractor brand name
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId <> ? ORDER BY RANDOM() LIMIT 1", (drugId,))
    answer = res.fetchone()[0]
    choices.append(answer)
    random.shuffle(choices)

    print("all brand names for drugId")
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId = ?", (drugId,))
    print(res.fetchall())

    return (string % inQuestion, choices, answer)


def useToNotBrand(string: str, disNum: int = 0):

    # get a use that has at least 3 brand names associated with it
    res = sql.curr().execute("SELECT use FROM drugUse GROUP BY use HAVING COUNT(DISTINCT drugId) >= 3 ORDER BY RANDOM() LIMIT 1")
    use = res.fetchone()[0]

    # get 3 brand names associated with this use
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId IN (SELECT drugId FROM drugUse WHERE use = ?) ORDER BY RANDOM() LIMIT 3", (use,))
    choices = [r[0] for r in res.fetchall()]

    # get a distractor brand name that does not have this use
    res = sql.curr().execute("SELECT name FROM drugBrand WHERE drugId NOT IN (SELECT drugId FROM drugUse WHERE use = ?) ORDER BY RANDOM() LIMIT 1", (use,))
    answer = res.fetchone()[0]

    choices.append(answer)
    random.shuffle(choices)

    if disNum > 0:
        # replace number with different brand distractors that do not have same use in distractorUse
        res = sql.curr().execute("SELECT brand FROM distractor WHERE id NOT IN (SELECT distractorId FROM distractorUse WHERE use = ?) ORDER BY RANDOM() LIMIT ?", (use, disNum,))
        replacements = [r[0] for r in res.fetchall()]
        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]


    return (string % use, choices, answer)

def genericToUse(string: str):
    # Get a generic drug
    res = sql.read("SELECT drugId, name FROM drugGeneric ORDER BY RANDOM() LIMIT 1")
    drugId, inQuestion = res.fetchone()

    # get a use for the drug
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    answer = res.fetchone()[0]

    # get 3 distinct distractor uses that are not associated with this drug
    res = sql.curr().execute("SELECT DISTINCT use FROM drugUse WHERE drugId NOT IN (SELECT drugId FROM drugUse WHERE use = ?) ORDER BY RANDOM() LIMIT 3", (answer,))
    choices = [r[0] for r in res.fetchall()]

    choices.append(answer)
    random.shuffle(choices)

    # res = sql.read(f"SELECT class FROM drugPClass WHERE drugId = {drugId}")
    # pclass = res.fetchone()[0]

    # print(pclass)

    # # get three uses that are associated with drugs of the same class but not this drug
    # res = sql.curr().execute("""
    #     SELECT DISTINCT du_other.use
    #     FROM drugUse du_target
    #     JOIN drugPClass pc_target
    #       ON pc_target.drugId = du_target.drugId
    #     JOIN drugPClass pc_other
    #       ON pc_other.class = pc_target.class
    #     JOIN drugUse du_other
    #       ON du_other.drugId = pc_other.drugId
    #     WHERE du_target.drugId = ?
    #       AND du_other.drugId <> pc_target.drugId
    #     ORDER BY RANDOM()
    #     LIMIT 3
    #     """, (drugId, ))
    # distractors = [r[0] for r in res.fetchall()]

    # answer = use
    # choices = [answer]
    # choices.extend(distractors)
    # random.shuffle(choices)


    return (string % inQuestion, choices, answer)


def genericToNotUse(string: str):
    # get a generic drug with at least 3 uses
    res = sql.read("""
        SELECT drugId, name FROM drugGeneric WHERE drugId IN (
            SELECT drugId FROM drugUse
            GROUP BY drugId HAVING COUNT(drugId) >= 3
        )
        ORDER BY RANDOM() LIMIT 1""")
    out = res.fetchone()
    

    drugId = out[0]
    inQuestion = out[1]
    
    question = string % inQuestion

    # get a use that is not associated with the generic drug
    res = sql.curr().execute("""
        SELECT use FROM drugUse
        WHERE use NOT IN (
            SELECT use FROM drugUse WHERE drugId = ?
        )
        ORDER BY RANDOM() LIMIT 1
        """, (drugId,))
    answer = res.fetchone()[0]
    
    # get three uses associated with the generic drug
    res = sql.curr().execute("""
        SELECT use FROM drugUse WHERE drugId = ?
        ORDER BY RANDOM() LIMIT 3
        """, (drugId,))
    
    choices = [answer]
    choices.extend([r[0] for r in res.fetchall()])
    random.shuffle(choices)
    
    return (question, choices, answer)

def brandToUse(string: str):
    # Get a generic drug
    res = sql.read("SELECT * FROM drugBrand ORDER BY RANDOM() LIMIT 1")
    drugId, inQuestion = res.fetchone()

    # get a use for the drug
    res = sql.read("SELECT use FROM drugUse WHERE drugId = %s ORDER BY RANDOM() LIMIT 1" % drugId)
    answer = res.fetchone()[0]

    # get 3 distinct distractor uses that are not associated with this drug
    res = sql.curr().execute("SELECT DISTINCT use FROM drugUse WHERE drugId NOT IN (SELECT drugId FROM drugUse WHERE use = ?) ORDER BY RANDOM() LIMIT 3", (answer,))
    distractors = [r[0] for r in res.fetchall()]

    choices = [answer]
    choices.extend(distractors)
    random.shuffle(choices)

    return (string % inQuestion, choices, answer)

def brandToNotUse(string: str):
    # get a generic drug with at least 3 uses
    res = sql.read("""
        SELECT drugId, name FROM drugBrand WHERE drugId IN (
            SELECT drugId FROM drugUse
            GROUP BY drugId HAVING COUNT(drugId) >= 3
        )
        ORDER BY RANDOM() LIMIT 1""")
    drugId, inQuestion = res.fetchone()



    # get a use that is not associated with the generic drug
    res = sql.curr().execute("""
        SELECT use FROM drugUse
        WHERE use NOT IN (
            SELECT use FROM drugUse WHERE drugId = ?
        )
        ORDER BY RANDOM() LIMIT 1
        """, (drugId,))
    answer = res.fetchone()[0]
    
    # get three uses associated with the generic drug
    res = sql.curr().execute("""
        SELECT use FROM drugUse WHERE drugId = ?
        ORDER BY RANDOM() LIMIT 3
        """, (drugId,))
    
    choices = [answer]
    choices.extend([r[0] for r in res.fetchall()])
    random.shuffle(choices)
    
    return (string % inQuestion, choices, answer)

def useToGeneric(string: str):

    # pick a random use
    res = sql.read("""
        SELECT DISTINCT use FROM drugUse
        ORDER BY RANDOM() LIMIT 1""")
    use = res.fetchone()[0]

    question = string % use

    # pick a random generic drug that has this use
    res = sql.curr().execute("""
    SELECT name FROM drugGeneric WHERE drugId IN (
        SELECT drugId FROM drugUse WHERE use = ?
    )
    ORDER BY RANDOM() LIMIT 1""", (use,))
    answer = res.fetchone()[0]

    # pick up to 3 random generic drugs that do not have this use
    res = sql.curr().execute("""
    SELECT name FROM drugGeneric WHERE drugId IN (
        SELECT drugId FROM drugGeneric EXCEPT
        SELECT drugId FROM drugUse WHERE use = ?
    )
    ORDER BY RANDOM() LIMIT 3;
    """, (use,))

    choices = [answer]
    choices.extend([r[0] for r in res.fetchall()])
    random.shuffle(choices)

    return (question, choices, answer)

def useToBrand(string: str, disNum: int = 0):

    # pick a random use
    res = sql.read("""
        SELECT DISTINCT use FROM drugUse
        ORDER BY RANDOM() LIMIT 1""")
    use = res.fetchone()[0]

    question = string % use

    # pick a random generic drug that has this use
    res = sql.curr().execute("""
    SELECT name FROM drugBrand WHERE drugId IN (
        SELECT drugId FROM drugUse WHERE use = ?
    )
    ORDER BY RANDOM() LIMIT 1""", (use,))
    answer = res.fetchone()[0]
    
    # pick up to 3 random generic drugs that do not have this use
    res = sql.curr().execute("""
    SELECT name FROM drugBrand WHERE drugId IN (
        SELECT drugId FROM drugBrand EXCEPT
        SELECT drugId FROM drugUse WHERE use = ?
    )
    ORDER BY RANDOM() LIMIT 3;
    """, (use,))

    choices = []
    choices.extend([r[0] for r in res.fetchall()])

    for i in range(min(disNum, len(choices))):
        # replace number with different brand distractors that do not have same use in distractorUse
        res = sql.curr().execute("SELECT brand FROM distractor WHERE id NOT IN (SELECT distractorId FROM distractorUse WHERE use = ?) ORDER BY RANDOM() LIMIT 1", (use,))
        replacement = res.fetchone()[0]
        print(replacement)
        choices[i] = replacement

    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)

def useToGenericOrBrand(string: str, disNum: int = 0):
    # pick a random use
    res = sql.read("""
        SELECT DISTINCT use FROM drugUse
        ORDER BY RANDOM() LIMIT 1""")
    use = res.fetchone()[0]

    question = string % use

    # pick a random generic drug that has this use
    res = sql.curr().execute("""
    SELECT name FROM (
        SELECT drugId, name FROM drugGeneric
        UNION
        SELECT drugId, name FROM drugBrand
    ) WHERE drugId IN (
        SELECT drugId FROM drugUse WHERE use = ?
    )
    ORDER BY RANDOM() LIMIT 1""", (use,))
    answer = res.fetchone()[0]
    
    # pick up to 3 random generic drugs that do not have this use
    res = sql.curr().execute("""
    SELECT name FROM (
        SELECT drugId, name FROM drugGeneric
        UNION
        SELECT drugId, name FROM drugBrand
    ) WHERE drugId IN (
        SELECT drugId FROM drugGeneric EXCEPT
        SELECT drugId FROM drugUse WHERE use = ?
    )
    ORDER BY RANDOM() LIMIT 3;
    """, (use,))

    choices = []
    choices.extend([r[0] for r in res.fetchall()])

    if disNum > 0:
        # replace number with distractor brands
        res = sql.curr().execute("SELECT brand FROM distractor WHERE id NOT IN (SELECT distractorId FROM distractorUse WHERE use = ?) ORDER BY RANDOM() LIMIT ?", (use, disNum,))
        replacements = [r[0] for r in res.fetchall()]
        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]

    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)

def brand3ToUse(string: str):
    
    # pick a use that has at least 3 drugs associated with it
    res = sql.read("""
        SELECT use, COUNT(DISTINCT drugId) AS drug_count
        FROM drugUse
        GROUP BY use
        HAVING COUNT(DISTINCT drugId) >= 3
        ORDER BY RANDOM() LIMIT 1;
        """)
    use = res.fetchone()[0]
    
    # pick three drug brands associated with the chosen use
    res = sql.curr().execute("""
        SELECT name, drugId FROM drugBrand WHERE drugId IN (
            SELECT drugId from drugUse WHERE use = ?
        ) ORDER BY RANDOM() LIMIT 3
        """, (use,))
    
    out = res.fetchall()
    threeBrands = tuple([r[0] for r in out])
    threeIds = tuple([r[1] for r in out])
    
    question = string % threeBrands
    
    # pick three uses that are not associated with any of the chosen three drugs
    res = sql.curr().execute("""
        SELECT DISTINCT use FROM drugUse WHERE drugId NOT IN (
            SELECT drugId FROM drugUse WHERE use IN (?,?,?)
        )
        ORDER BY RANDOM() LIMIT 3
        """, threeIds)
    
    choices = [use]
    choices.extend([r[0] for r in res.fetchall()])
    random.shuffle(choices)
    
    return(question, choices, use)

def brandAndGenericToGeneric(string: str, disNum: int = 0):
    # get a generic drug with a - in it
    res = sql.read("""
        SELECT name, drugId FROM drugGeneric WHERE name LIKE '%-%'
        ORDER BY RANDOM() LIMIT 1
    """)
    out = res.fetchone()
    
    # name has dashes, split by them
    drugs = out[0].split('-')
    drugId = out[1]
    
    # we're going to pick the first two drugs. randomize it.
    # also handles names with 3 or more drugs
    random.shuffle(drugs)

    # get a brand name of this drugId
    res = sql.read(f"""
        SELECT name FROM drugBrand WHERE drugId = {drugId}
        ORDER BY RANDOM() LIMIT 1
    """)

    question = string % (res.fetchone()[0], drugs[0])
    answer = drugs[1]

    # get three generic drugs that are not the same
    res = sql.read("""
        SELECT name FROM drugGeneric WHERE name NOT LIKE '%-%'
        ORDER BY RANDOM() LIMIT 3
    """)

    choices = []
    choices.extend([r[0] for r in res.fetchall()])

    if disNum > 0:
        # replace number with distractor combo drugs separated by dashes
        res = sql.curr().execute("SELECT generic FROM distractor WHERE generic LIKE '%-%' ORDER BY RANDOM() LIMIT ?", (disNum,))
        replacements = [r[0] for r in res.fetchall()]
        print(replacements)

        for i in range(min(disNum, len(choices))):
            choices[i] = random.choice(replacements[i].split('-'))
        


    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)

def genericAndUseToBrand(string: str, disNum: int = 0):
    # get a generic drug
    res = sql.read("""
        SELECT * FROM drugGeneric
        ORDER BY RANDOM() LIMIT 1""")
    out = res.fetchone()
    
    drugId = out[0]
    inQuestion = out[1]
    
    # get a use for the drug
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    
    question = string % (inQuestion, res.fetchone()[0])

    # Choose the correct brand name
    res = sql.read(f"""
        SELECT name FROM drugBrand
        WHERE drugId = {drugId}
        """)
    brandNames = [r[0] for r in res.fetchall()]
    answer = random.choice(brandNames)

    # Choose three distractors that are not the same drug and not the same use
    res = sql.curr().execute(f"""
        SELECT name FROM drugBrand
        WHERE drugId <> {drugId}
        AND drugId NOT IN (SELECT drugId FROM drugUse WHERE use = (SELECT use FROM drugUse WHERE drugId = {drugId} LIMIT 1))
        ORDER BY RANDOM()
        LIMIT 3
        """)

    choices = [r[0] for r in res.fetchall()]

    if disNum > 0:
        # replace number with different brand distractors that do not have same use in distractorUse
        res = sql.curr().execute("SELECT brand FROM distractor WHERE id NOT IN (SELECT distractorId FROM distractorUse WHERE use = ?) ORDER BY RANDOM() LIMIT ?", (drugId, disNum,))
        replacements = [r[0] for r in res.fetchall()]
        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]

    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)

def genericAndUseToBrandSamePClass(string: str):
    # get a generic drug
    res = sql.read("""
        SELECT * FROM drugGeneric
        ORDER BY RANDOM() LIMIT 1""")
    out = res.fetchone()
    
    drugId = out[0]
    inQuestion = out[1]
    
    # get a use for the drug
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    
    question = string % (inQuestion, res.fetchone()[0])
    
    # get pclass
    res = sql.read(f"SELECT class FROM drugPClass WHERE drugId = {drugId}")
    pclass = res.fetchone()[0]

    # Choose the correct brand name
    res = sql.read(f"""
        SELECT name FROM drugBrand
        WHERE drugId = {drugId}
        """)
    brandNames = [r[0] for r in res.fetchall()]
    answer = random.choice(brandNames)

    # Choose three distractors
    res = sql.read(f"""
        SELECT DISTINCT b.name
        FROM drugPClass AS d1
        JOIN drugPClass AS d2 ON d1.class = d2.class
        JOIN drugBrand AS b ON b.drugId = d2.drugId
        WHERE d1.drugId = {drugId}
        AND d2.drugId <> {drugId}
        ORDER BY RANDOM()
        LIMIT 3
        """)

    choices = [r[0] for r in res.fetchall()]
    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)



def brandAndUseToGeneric(string: str, disNum: int = 0):
    # get a brand drug
    res = sql.read("""
        SELECT * FROM drugBrand
        ORDER BY RANDOM() LIMIT 1""")
    out = res.fetchone()
    
    drugId = out[0]
    inQuestion = out[1]
    
    # get a use for the drug
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    
    question = string % (inQuestion, res.fetchone()[0])

    # Choose the correct generic name
    res = sql.read(f"""
        SELECT name FROM drugGeneric
        WHERE drugId = {drugId}
        """)
    brandNames = [r[0] for r in res.fetchall()]
    answer = random.choice(brandNames)

    # Choose three distractors
    res = sql.read(f"""
        SELECT name FROM drugGeneric
        WHERE drugId <> {drugId}
        ORDER BY RANDOM()
        LIMIT 3
        """)

    choices = [r[0] for r in res.fetchall()]

    if disNum > 0:
        # replace number with different generic distractors that do not have same use in distractorUse
        res = sql.curr().execute("SELECT generic FROM distractor WHERE id NOT IN (SELECT distractorId FROM distractorUse WHERE use = ?) ORDER BY RANDOM() LIMIT ?", (drugId, disNum,))
        replacements = [r[0] for r in res.fetchall()]
        print(replacements)
        for i in range(min(disNum, len(choices))):
            choices[i] = replacements[i]

    choices.append(answer)
    random.shuffle(choices)

    return (question, choices, answer)

def genericAndUseToNotBrand(string: str, disNum: int = 0):
    # get a generic drug with at least 3 brand names
    res = sql.read("""
        SELECT name, drugId FROM drugGeneric WHERE drugId IN (
            SELECT drugId FROM drugBrand
            GROUP BY drugId HAVING COUNT(drugId) >= 3
        )
        ORDER BY RANDOM() LIMIT 1""")
    out = res.fetchone()
    
    drugId = out[1]
    inQuestion = out[0]
    
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId}")
    uses = [r[0] for r in res.fetchall()]
    
    # get a use from this drug
    res = sql.read(f"""
        SELECT use FROM drugUse WHERE drugId = {drugId}
        ORDER BY RANDOM() LIMIT 1
        """)
    use = res.fetchone()[0]
    
    question = string % (inQuestion, use)
    
    # get a brand drug that does not have this generic drug
    # answer
    res = sql.curr().execute(f"""
        SELECT name FROM drugBrand WHERE drugId NOT IN (
            SELECT drugId FROM drugGeneric WHERE name LIKE '%{inQuestion}%'
        ) AND drugId IN (
            SELECT drugId FROM drugUse WHERE use LIKE ?
        )
        ORDER BY RANDOM() LIMIT 1
    """, (use,))
    out = res.fetchone()
    if out == None:
        return genericAndUseToNotBrand(string, disNum)
    else:
        answer = out[0]
    
    choices = [answer]
    
    # get a brand drug that does not have this use but same generic
    res = sql.curr().execute("""
        SELECT name FROM drugBrand WHERE drugId NOT IN (
            SELECT drugId FROM drugUse WHERE use = ?
        ) AND drugId IN (
            SELECT drugId FROM drugGeneric WHERE name LIKE ?
        )
        ORDER BY RANDOM() LIMIT 1
    """, (use,inQuestion))
    
    out = res.fetchone()
    if out == None:
        return genericAndUseToNotBrand(string)
    else:
        choices.append(out[0])
    
    # get 2 brand drugs that have the correct use
    res = sql.curr().execute(f"""
        SELECT name FROM drugBrand WHERE drugId = {drugId}
        ORDER BY RANDOM() LIMIT 2
    """)
    choices.extend([r[0] for r in res.fetchall()])
    
    random.shuffle(choices)
    
    return (question, choices, answer)

# q = genericAndUseToNotBrand("You receive a prescription for %s with an 
# indication for %s. Which of the following brand name products contains the INCORRECT active ingredient?")

def brandAndUseToGenericCombo(string: str):
    
    # get a brand drug that has a - in its generic
    res = sql.read("""
        SELECT name, drugId FROM drugBrand WHERE drugId IN (
            SELECT drugId FROM drugGeneric WHERE name LIKE '%-%'
        )
        ORDER BY RANDOM() LIMIT 1
        """)
    
    out = res.fetchone()
    
    drugId = out[1]
    inQuestion = out[0]
    
    # get a use
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    question = string % (inQuestion, res.fetchone()[0])
    
    # get a name with a - in it
    res = sql.read(f"""
        SELECT name FROM drugGeneric WHERE drugId = {drugId} AND name LIKE '%-%'
        ORDER BY RANDOM() LIMIT 1
        """)
    answer = res.fetchone()[0]
    
    res = sql.read(f"SELECT class FROM drugPClass WHERE drugId = {drugId}")
    pclass = res.fetchone()[0]
    
    # get three generic drugs with - in it not like
    res = sql.curr().execute(f"""
        SELECT name FROM drugGeneric WHERE drugId <> {drugId} AND drugId IN (
            SELECT drugId FROM drugPClass WHERE class = '{pclass}'
        )
        ORDER BY RANDOM() LIMIT 3
        """)
    
    choices = [answer]
    choices.extend([r[0] for r in res.fetchall()])
    
    return (question, choices, answer)

#  q = brandAndUseToNotGenericCombo("You receive a prescription for %s 
# with an indication for %s. Which of the following generic name products is appropriate to dispense?")

def brandAndUseToGenericUseRelated(string: str):
    # get a brand and its uses
    res = sql.read("SELECT name, drugId FROM drugBrand ORDER BY RANDOM() LIMIT 1")
    inQuestion, drugId = res.fetchone()
    
    # get a use from this drug
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    use = res.fetchone()[0]
    question = string % (inQuestion, use)
    
    
    res = sql.read(f"SELECT name FROM drugGeneric WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    answer = res.fetchone()[0]
    
    # get three generic drugs that have the same use
    res = sql.curr().execute(f"""
        SELECT name FROM drugGeneric WHERE drugId <> {drugId}
        AND drugId IN (SELECT drugId FROM drugUse WHERE use = ?)
        ORDER BY RANDOM() LIMIT 3
        """, (use,))
    
    choices = [answer]
    choices.extend([r[0] for r in res.fetchall()])
    random.shuffle(choices)
    
    return (question, choices, answer)

#  q = brandAndUseToGenericUseRelated("You receive a prescription for %s 
# with an indication for %s. Which of the following generic name 
# products is appropriate to dispense?")

def brandAndUseToGenericUseNotRelated(string: str):
    # get a brand and its uses
    res = sql.read("SELECT name, drugId FROM drugBrand ORDER BY RANDOM() LIMIT 1")
    inQuestion, drugId = res.fetchone()
    
    # get a use from this drug
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    use = res.fetchone()[0]
    question = string % (inQuestion, use)
    
    
    res = sql.read(f"SELECT name FROM drugGeneric WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    answer = res.fetchone()[0]
    
    # get three generic drugs that have the same use
    res = sql.curr().execute(f"""
        SELECT name FROM drugGeneric WHERE drugId <> {drugId}
        AND drugId NOT IN (SELECT drugId FROM drugUse WHERE use = ?)
        ORDER BY RANDOM() LIMIT 3
        """, (use,))
    
    choices = [answer]
    choices.extend([r[0] for r in res.fetchall()])
    random.shuffle(choices)
    
    return (question, choices, answer)

def brandAndUseToGenericMixed(string: str):
    
    # pick a drugId that has at least 3 generic names
    res = sql.read("""
        SELECT DISTINCT drugId FROM drugGeneric GROUP BY drugId HAVING COUNT(drugId) > 2
        ORDER BY RANDOM() LIMIT 1
        """)
    drugId = res.fetchone()[0]
    
    res = sql.read(f"SELECT name FROM drugGeneric WHERE drugId = {drugId} ORDER BY RANDOM()")
    genericNames = [r[0] for r in res.fetchall()]
    
    # pick 3 random names and string them together
    answer = ", ".join(random.sample(genericNames, 3))
    
    choices = [answer]
    
    for _ in range(3):
        res = sql.read(f"SELECT name FROM drugGeneric WHERE drugId <> {drugId} ORDER BY RANDOM() LIMIT 1")
        print(res.fetchall())
        distNames = random.sample(genericNames, 2)
        distNames.append(res.fetchone()[0])
        random.shuffle(distNames)
        choices.append(", ".join(distNames))
    
    res = sql.read(f"SELECT name FROM drugBrand WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    brandName = res.fetchone()[0]
    res = sql.read(f"SELECT use FROM drugUse WHERE drugId = {drugId} ORDER BY RANDOM() LIMIT 1")
    exampleUse = res.fetchone()[0]
    question = string % (brandName, exampleUse)

    random.shuffle(choices)

    return (question, choices, answer)
# q = brandAndUseToGenericMixed("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")


# def make_question(template: int) -> tuple[Any, List[Any], Any]:
#     match template:
#         case 1:
#             q = genericToBrand("What is the correct brand name of %s?")
#         case 2:
#             q = brandToGeneric("What is the generic ingredient in %s?")
#         case 3:
#             q = brandToGeneric("Which of the following is the generic drug for %s?")
#         case 4:
#             q = genericToBrand("Which of the following is the brand name for %s?")
#         case 5:
#             q = genericToNotBrand("All of the following are brand names of %s EXCEPT:")
#         case 6:
#             q = useToNotBrand("Which of the following medications is NOT indicated for the treatment of %s?")
#         case 7:
#             q = genericToUse("%s is used to treat:")
#         case 8:
#             q = brandToUse("Which use is the most appropriate for %s?")
#         case 9:
#             q = brandToUse("Which of the following is an appropriate use for %s?")
#         case 10:
#             q = useToGeneric("Which of the following drugs can be used for %s?")
#         case 11:
#             q = useToGenericOrBrand("Which of the following drugs can be used for %s?")
#         case 12:
#             q = genericToUse("Which of the following is a common indication for %s?")
#         case 13:
#             q = genericToNotBrand("All of the following are brand names of %s EXCEPT:")
#         case 14:
#             q = brandToGeneric("%s is:")
#         case 15:
#             q = brandToGeneric("%s contains which of the following medications:")
#         case 16:
#             q = brandToUse("%s is approved for the treatment of:")
#         case 17:
#             q = brand3ToUse("%s, %s, %s can all be used for:")
#         case 18:
#             q = genericToNotUse("%s is indicated for treatment of all of the following EXCEPT:")
#         case 19:
#             q = useToBrand("Which of the following drugs is indicated for the treatment of %s?")
#         case 20:
#             q = brandAndGenericToGeneric("%s contains %s and which of the following drugs?")
#         case 21:
#             q = genericAndUseToBrand("You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?")
#         case 22:
#             q = genericAndUseToBrand("You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?")
#         case 23:
#             q = genericAndUseToBrand("You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?")
#         case 24:
#             q = genericAndUseToBrand("You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?")
#         case 25:
#             q = genericAndUseToBrand("You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?")
#         case 26:
#             q = genericAndUseToNotBrand("You receive a prescription for %s with an indication for %s. Which of the following brand name products contains the INCORRECT active ingredient?")
#         case 27:
#             q = brandAndUseToGenericCombo("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 28:
#             q = brandAndUseToGeneric("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 29:
#             q = brandAndUseToGenericUseRelated("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 30:
#             q = brandAndUseToGenericUseNotRelated("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 31:
#             q = brandAndUseToGeneric("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 32:
#             q = brandAndUseToGeneric("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 33:
#             q = brandAndUseToGenericMixed("You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?")
#         case 34:
#             q = brandToUse("You receive a prescription for %s. Which of the following indications is appropriate in order to dispense?")
#         case 35:
#             q = brandToUse("You receive a prescription for %s. Which of the following indications is appropriate in order to dispense?")
#         case 36:
#             q = brandToUse("You receive a prescription for %s. Which of the following indications is appropriate in order to dispense?")
#         case 37:
#             q = brandToUse("You receive a prescription for %s. Which of the following indications is appropriate in order to dispense?")
#         case 38:
#             q = brandToUse("You receive a prescription for %s. Which of the following indications is appropriate in order to dispense?")
#         case 39:
#             q = brandToUse("You receive a prescription for %s. Which of the following indications is appropriate in order to dispense?")
#         case 40:
#             q = genericToBrandAndUse("A pharmacist is verifying a prescription for %s. Which of the following correctly matches the brand name and FDA-approved indication of this drug?")
#         case 41:
#             q = genericAndUseToBrandSamePClass("You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?")
#         case _:
#             q = genericToBrand("out of range %s")
            
#     return q

# repeat_amount = 1

# f = open("questions.md", "w")


# templates = [1, 2, 4, 5, 6, 9, 10, 14, 15, 20, 21, 26, 27, 40, 41]
# templates = [7]

# for i in range(41):
#     if i == 33:
#         continue
#     f.write("# Template Number " + str(i) + "\n\n")
#     for j in range(repeat_amount):
#         q = make_question(i)
#         f.write(str(j+1) + ". " + q[0] + "\n")
#         for choice in q[1]:
#             f.write(choice + "\n")

#         f.write("\nCorrect: " + q[2] + "\n\n---\n\n")


# f.close()

templates = {
    1:  "What is the correct brand name of %s?",
    2:  "What is the generic ingredient in %s?",
    5:  "All of the following are brand names of %s EXCEPT:",
    6:  "Which of the following medications is NOT indicated for the treatment of %s?",
    7:  "%s is used to treat:",
    8:  "Which use is the most appropriate for %s?",
    10: "Which of the following drugs can be used for %s?",
    11: "Which of the following drugs can be used for %s?",
    17: "%s, %s, and %s can all be used for:",
    18: "%s is indicated for treatment of all the following EXCEPT:",
    19: "Which of the following drugs is indicated for the treatment of %s?",
    20: "%s contains %s and which of the following drugs?",
    21: "You receive a prescription for %s with an indication for %s. Which of the following brand name products is appropriate to dispense?",
    26: "You receive a prescription for %s with an indication for %s. Which of the following brand name products contains the INCORRECT active ingredient?",
    31: "You receive a prescription for %s with an indication for %s. Which of the following generic name products is appropriate to dispense?",
    40: "A pharmacist is verifying a prescription for %s Which of the following correctly matches the brand name and FDA-approved indication of this drug?"
}


# level 1
# print(genericToBrand(templates[1]))
# print(brandToGeneric(templates[2]))

# level 2
# print(genericToNotBrand(templates[5]))
# print(useToNotBrand(templates[6]))
# print(genericToUse(templates[7]))

# level 3
# print(brandToUse(templates[8]))

# level 4
# print(useToGeneric(templates[10]))
# print(useToBrand(templates[19]))

# level 5
# print(genericToNotUse(templates[18]))
# print(brandAndGenericToGeneric(templates[20]))

# level 6
# print(genericAndUseToBrand(templates[21]))
# print(genericAndUseToNotBrand(templates[26]))

# level 7
# print(brandAndUseToGeneric(templates[31]))
# print(genericToBrandAndUse(templates[40]))

# level 8
# print(genericToBrand(templates[1], 1))
# print(brandToGeneric(templates[2], 1))

# level 9
# print(genericToBrand(templates[1], 2))
# print(brandToGeneric(templates[2], 2))

# level 10
# print(useToNotBrand(templates[6], random.randint(1, 3)))
# print(useToGenericOrBrand(templates[11], random.randint(1, 3)))

# level 11
# print(brand3ToUse(templates[17]))
# print(brandAndGenericToGeneric(templates[20], random.randint(1, 3)))

# level 12
# print(genericAndUseToBrand(templates[21], random.randint(1, 3)))
# print(brandAndUseToGeneric(templates[31], random.randint(1, 3)))
# print(genericToBrandAndUse(templates[40], random.randint(1, 3)))


repeat = 100
# print to markdown file
with open("questions.md", "w") as f:

    # level 1
    f.write("# Level 1 Template 1\n\n")
    for j in range(repeat):
        q = genericToBrand(templates[1])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 1 Template 2\n\n")
    for j in range(repeat):
        q = brandToGeneric(templates[2])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")


    # level 2
    f.write("# Level 2 Template 5\n\n")
    for j in range(repeat):
        q = genericToNotBrand(templates[5])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 2 Template 6\n\n")
    for j in range(repeat):
        q = useToNotBrand(templates[6])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 3
    f.write("# Level 3 Template 8\n\n")
    for j in range(repeat):
        q = brandToUse(templates[8])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 4
    f.write("# Level 4 Template 10\n\n")
    for j in range(repeat):
        q = useToGeneric(templates[10])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 4 Template 19\n\n")
    for j in range(repeat):
        q = useToBrand(templates[19])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 5
    f.write("# Level 5 Template 18\n\n")
    for j in range(repeat):
        q = genericToNotUse(templates[18])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 5 Template 20\n\n")
    for j in range(repeat):
        q = brandAndGenericToGeneric(templates[20])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 6
    f.write("# Level 6 Template 21\n\n")
    for j in range(repeat):
        q = genericAndUseToBrand(templates[21])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 6 Template 26\n\n")
    for j in range(repeat):
        q = genericAndUseToNotBrand(templates[26])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")


    # level 7
    f.write("# Level 7 Template 31\n\n")
    for j in range(repeat):
        q = brandAndUseToGeneric(templates[31])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 7 Template 40\n\n")
    for j in range(repeat):
        q = genericToBrandAndUse(templates[40])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 8
    f.write("# Level 8 Template 1\n\n")
    for j in range(repeat):
        q = genericToBrand(templates[1], 1)
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")
    f.write("# Level 8 Template 2\n\n")
    for j in range(repeat):
        q = brandToGeneric(templates[2], 1)
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 9
    f.write("# Level 9 Template 1\n\n")
    for j in range(repeat):
        q = genericToBrand(templates[1], 2)
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")
    f.write("# Level 9 Template 2\n\n")
    for j in range(repeat):
        q = brandToGeneric(templates[2], 2)
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")

        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 10
    f.write("# Level 10 Template 6\n\n")
    for j in range(repeat):
        q = useToNotBrand(templates[6], random.randint(1, 3))
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    f.write("# Level 10 Template 11\n\n")
    for j in range(repeat):
        q = useToGenericOrBrand(templates[11], random.randint(1, 3))
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 11
    f.write("# Level 11 Template 17\n\n")
    for j in range(repeat):
        q = brand3ToUse(templates[17])
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")
    f.write("# Level 11 Template 20\n\n")
    for j in range(repeat):
        q = brandAndGenericToGeneric(templates[20], random.randint(1, 3))
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # level 12
    f.write("# Level 12 Template 21\n\n")
    for j in range(repeat):
        q = genericAndUseToBrand(templates[21], random.randint(1, 3))
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")
    f.write("# Level 12 Template 31\n\n")
    for j in range(repeat):
        q = brandAndUseToGeneric(templates[31], random.randint(1, 3))
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")
    f.write("# Level 12 Template 40\n\n")
    for j in range(repeat):
        q = genericToBrandAndUse(templates[40], random.randint(1, 3))
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")

    # Level 13
    f.write("# Level 13 Template 19\n\n")
    for j in range(repeat):
        q = useToBrand(templates[19], 1)
        f.write(str(j+1) + ". " + q[0] + "\n")
        for choice in q[1]:
            f.write(choice + "\n")
        f.write("\nCorrect: " + q[2] + "\n\n---\n\n")
