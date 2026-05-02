import pandas as pd
import sql
import sqlite3

# excelFile = 'brandGenericUse.xlsx'
# df = pd.read_excel(excelFile, engine='openpyxl')


# count = 0
# for row in df.itertuples(index = True):
#     print(row._fields)
#     print(row[0])

#     count += 1
#     if count > 3:
#         break


def build_db():
    # input("about to delete database. press enter to continue or ctrl-c to quit out")
    sql.delete_db()

    excelFile = 'brandGenericUse.xlsx'
    df = pd.read_excel(excelFile, engine='openpyxl')

    for row in df.itertuples(index = True):

        # res = sql.curr().execute(
        #     "SELECT * FROM drugUse WHERE use = ?",
        #     (use,)
        # )
        # print(row.KEY)

        sql.curr().execute(
            "INSERT INTO drug(id, base) VALUES (?, ?)",
            (row.Index, row.base)
        )

        for text in row.generic.split(","):
            sql.curr().execute(
                "INSERT INTO drugGeneric(drugId, name) VALUES (?, ?)",
                (row.Index, text.strip())
            )

        for text in row.brand.split(","):
            sql.curr().execute(
                "INSERT INTO drugBrand(drugId, name) VALUES (?, ?)",
                (row.Index, text.strip())
            )

        for text in row.use.split(","):
            sql.curr().execute(
                "INSERT INTO drugUse(drugId, use) VALUES (?, ?)",
                (row.Index, text.strip())
            )

        for text in row.dosageForm.split(","):
            sql.curr().execute(
                "INSERT INTO dosageForm(drugId, form) VALUES (?, ?)",
                (row.Index, text.strip())
            )

        for text in row.pclass.split(","):
            sql.curr().execute(
                "INSERT INTO drugPClass(drugId, class) VALUES (?, ?)",
                (row.Index, text.strip())
            )

    df = pd.read_excel("distractors.xlsx", engine='openpyxl')

    for row in df.itertuples(index = True):

        # res = sql.curr().execute(
        #     "SELECT * FROM drugUse WHERE use = ?",
        #     (use,)
        # )
        # print(row.KEY)

        sql.curr().execute(
            "INSERT INTO distractor(id, key, generic, brand) VALUES (?, ?, ?, ?)",
            (row.Index, row.KEY, row.generic, row.brand)
        )

        for text in row.use.split(","):
            sql.curr().execute(
                "INSERT INTO distractorUse(distractorId, use) VALUES (?, ?)",
                (row.Index, text.strip())
            )

    # remove brand names that are blank
    sql.curr().execute("DELETE FROM drugBrand WHERE name = ''")

    sql.connection.commit()



if __name__ == "__main__":
    build_db()

