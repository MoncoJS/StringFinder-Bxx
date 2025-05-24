import static org.junit.Assert.*;

import org.junit.Test;

public class TestCorrectAllLonger {

	@Test
	public void test() {
		StringFinder a = new StringFinder(new Secret("ABCDEFG"));
		
		// correct string
		assertEquals(4,a.getGoal().evaluate("ABCDEFGHIJK"));
	}

}
